"""
drone_mission/vehicle/telemetry.py

Background telemetry listener.

Runs a daemon thread that continuously drains the MAVLink receive buffer,
caches the latest message of each monitored type, and maintains a
timestamped ring buffer for future time-aligned georeferencing (Phase 12).

Architecture
~~~~~~~~~~~~
::

    Main thread                      Telemetry thread (daemon)
        │                                 │
        ├─ send heartbeat @ 1 Hz          ├─ master.recv_match(blocking, timeout=0.1)
        ├─ send velocity  @ 10 Hz         ├─ update _latest[msg_type]
        ├─ read telem.get_position()  ◄───┤─ append to _ring buffer
        │                                 │
        └─ (never calls recv_match)       └─ detect heartbeat loss

Thread safety
~~~~~~~~~~~~~
* ``_latest`` dict and ``_ring`` deque are guarded by ``_lock``.
* The main thread reads via ``get_message()`` / ``find_nearest_sample()``.
* The background thread is the only writer.
"""

import collections
import logging
import threading
import time
from dataclasses import dataclass
from typing import Any, Deque, Dict, List, Optional

from drone_mission import config

logger = logging.getLogger(__name__)


# =============================================================================
# Ring-buffer sample
# =============================================================================

@dataclass
class TelemetrySample:
    """One combined position + attitude snapshot for the ring buffer.

    Used by georeferencing (Phase 12) to find the telemetry state
    closest to a given camera-frame timestamp.

    All angular values are in **radians**.
    """

    timestamp: float       # time.time() epoch seconds (local clock)
    time_boot_ms: int      # ArduPilot monotonic boot time (ms)

    # Position
    lat: float             # degrees
    lon: float             # degrees
    alt_relative: float    # metres, relative to home
    alt_msl: float         # metres, above mean sea level

    # Attitude
    roll: float            # radians
    pitch: float           # radians
    yaw: float             # radians

    # Velocity (NED, m/s)
    vx: float
    vy: float
    vz: float


# =============================================================================
# Telemetry buffer
# =============================================================================

class TelemetryBuffer:
    """Thread-safe cache of the latest MAVLink messages plus a time-series
    ring buffer.

    Usage::

        buf = TelemetryBuffer(master)
        buf.start()
        ...
        pos_msg = buf.get_message('GLOBAL_POSITION_INT')
        sample  = buf.find_nearest_sample(frame_timestamp)
        ...
        buf.stop()
    """

    def __init__(self, master) -> None:
        """
        Args:
            master: A ``pymavlink.mavutil.mavlink_connection`` instance.
                    The telemetry thread becomes the exclusive reader
                    of this connection.
        """
        self._master = master
        self._lock = threading.Lock()
        self._running = False
        self._thread: Optional[threading.Thread] = None

        # Latest-message cache:  msg_type_string -> raw pymavlink message
        self._latest: Dict[str, Any] = {}

        # Timestamped ring buffer for georeferencing
        self._ring: Deque[TelemetrySample] = collections.deque(
            maxlen=config.TELEMETRY_RING_BUFFER_SIZE
        )

        # Heartbeat tracking
        self._last_heartbeat_time: float = 0.0
        self._heartbeat_event = threading.Event()

        # Extracted heartbeat fields (updated atomically under the lock)
        self._armed: bool = False
        self._mode_id: Optional[int] = None

        # ----- COMMAND_ACK handling (P4) -----
        # Queue of received COMMAND_ACKs, newest last.
        # The vehicle layer calls clear_command_ack() before sending a
        # command, then wait_command_ack() to block until the matching
        # ACK arrives or times out.
        self._ack_lock = threading.Lock()
        self._ack_queue: Deque[Any] = collections.deque(maxlen=50)
        self._ack_event = threading.Event()

    # -----------------------------------------------------------------
    # Public control
    # -----------------------------------------------------------------

    def start(self) -> None:
        """Launch the background receive thread (daemon, auto-exits)."""
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(
            target=self._receive_loop,
            name="telemetry-rx",
            daemon=True,
        )
        self._thread.start()
        logger.info("Telemetry receive thread started")

    def stop(self) -> None:
        """Signal the background thread to exit and wait for it."""
        self._running = False
        if self._thread is not None and self._thread.is_alive():
            self._thread.join(timeout=3.0)
        logger.info("Telemetry receive thread stopped")

    # -----------------------------------------------------------------
    # Heartbeat / connection health
    # -----------------------------------------------------------------

    @property
    def heartbeat_healthy(self) -> bool:
        """``True`` if a vehicle heartbeat was received within
        ``config.HEARTBEAT_TIMEOUT_S``.

        This tracks whether the *vehicle* is actively communicating,
        not merely whether the Python socket/serial transport exists.
        A ``True`` return means the autopilot is alive and sending.
        """
        if self._last_heartbeat_time == 0.0:
            return False
        return (time.time() - self._last_heartbeat_time) < config.HEARTBEAT_TIMEOUT_S

    @property
    def last_heartbeat_age_s(self) -> Optional[float]:
        """Seconds since the last vehicle heartbeat, or ``None``
        if no heartbeat has ever been received."""
        if self._last_heartbeat_time == 0.0:
            return None
        return time.time() - self._last_heartbeat_time

    @property
    def armed(self) -> bool:
        """``True`` if the vehicle is armed (from latest HEARTBEAT)."""
        return self._armed

    @property
    def mode_id(self) -> Optional[int]:
        """Current ArduPilot custom-mode ID, or ``None`` if unknown."""
        return self._mode_id

    # -----------------------------------------------------------------
    # Message access
    # -----------------------------------------------------------------

    def get_message(self, msg_type: str) -> Optional[Any]:
        """Return the most-recently cached message of ``msg_type``.

        Args:
            msg_type: MAVLink message type string,
                      e.g. ``'ATTITUDE'``, ``'GLOBAL_POSITION_INT'``.

        Returns:
            The raw pymavlink message object, or ``None`` if the
            message type has never been received.
        """
        with self._lock:
            return self._latest.get(msg_type)

    def get_ring_buffer_copy(self) -> List[TelemetrySample]:
        """Snapshot of the entire ring buffer (oldest-first list)."""
        with self._lock:
            return list(self._ring)

    def find_nearest_sample(
        self, timestamp: float
    ) -> Optional[TelemetrySample]:
        """Find the ring-buffer sample whose timestamp is closest to
        *timestamp*.

        Used by georeferencing to time-align a camera frame with
        vehicle state.

        Args:
            timestamp: Target time (``time.time()`` epoch seconds).

        Returns:
            The nearest ``TelemetrySample``, or ``None`` if the buffer
            is empty.
        """
        with self._lock:
            if not self._ring:
                return None
            # Linear scan is fine for ≤500 samples
            return min(self._ring, key=lambda s: abs(s.timestamp - timestamp))

    # -----------------------------------------------------------------
    # COMMAND_ACK handling  (public API for vehicle layer)
    # -----------------------------------------------------------------

    def clear_command_acks(self) -> None:
        """Discard all queued COMMAND_ACKs.

        Call this immediately before sending a COMMAND_LONG so that
        ``wait_command_ack()`` will not match a stale ACK from a
        previous command.
        """
        with self._ack_lock:
            self._ack_queue.clear()
            self._ack_event.clear()

    def wait_command_ack(
        self, command_id: int, timeout: float = 5.0
    ) -> Optional[int]:
        """Wait for a COMMAND_ACK matching *command_id*.

        Blocks until a matching ACK arrives or *timeout* expires.

        Args:
            command_id: The MAV_CMD_* integer to match against
                        ``COMMAND_ACK.command``.
            timeout:    Maximum seconds to wait.

        Returns:
            The ``MAV_RESULT`` integer (0 = ACCEPTED) if a matching
            ACK was found, or ``None`` on timeout.
        """
        deadline = time.time() + timeout
        while time.time() < deadline:
            # Scan the queue for a matching ACK
            with self._ack_lock:
                for ack in self._ack_queue:
                    if ack.command == command_id:
                        return ack.result
            # Wait for the receive thread to signal a new ACK arrival
            remaining = deadline - time.time()
            if remaining <= 0:
                break
            self._ack_event.wait(timeout=min(remaining, 0.1))
            self._ack_event.clear()
        return None

    # -----------------------------------------------------------------
    # Background thread
    # -----------------------------------------------------------------

    def _receive_loop(self) -> None:
        """Continuously receive and cache MAVLink messages.

        Runs as a daemon thread.  Uses a short blocking timeout
        (0.1 s) so the thread can check ``_running`` and exit cleanly
        on shutdown.
        """
        while self._running:
            try:
                msg = self._master.recv_match(blocking=True, timeout=0.1)
                if msg is None:
                    continue

                msg_type = msg.get_type()
                if msg_type == "BAD_DATA":
                    continue

                now = time.time()

                # Cache latest message
                with self._lock:
                    self._latest[msg_type] = msg

                # Dispatch to specialised handlers
                if msg_type == "HEARTBEAT":
                    self._process_heartbeat(msg, now)
                elif msg_type == "GLOBAL_POSITION_INT":
                    self._maybe_append_ring(msg, now)
                elif msg_type == "COMMAND_ACK":
                    self._process_command_ack(msg)

            except Exception as e:
                if self._running:
                    logger.warning("Telemetry receive error: %s", e)
                    time.sleep(0.1)  # back-off on repeated errors

    # -----------------------------------------------------------------
    # Heartbeat processing
    # -----------------------------------------------------------------

    def _process_heartbeat(self, msg, now: float) -> None:
        """Extract armed state and custom mode from a HEARTBEAT."""
        from pymavlink import mavutil          # deferred import

        self._last_heartbeat_time = now
        self._heartbeat_event.set()

        armed = bool(
            msg.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED
        )
        mode_id = msg.custom_mode

        with self._lock:
            self._armed = armed
            self._mode_id = mode_id

    # -----------------------------------------------------------------
    # Ring-buffer update
    # -----------------------------------------------------------------

    def _maybe_append_ring(self, pos_msg, now: float) -> None:
        """Combine the latest GLOBAL_POSITION_INT with the latest
        ATTITUDE and append a ``TelemetrySample`` to the ring buffer.

        If no ATTITUDE has been received yet, skip — we cannot build a
        useful combined sample without attitude data.

        Note: the position and attitude messages may not share the
        exact same ``time_boot_ms``.  For Phase 1 this small mismatch
        is acceptable.  Phase 12 will add proper interpolation.
        """
        with self._lock:
            att_msg = self._latest.get("ATTITUDE")

        if att_msg is None:
            return  # cannot build a useful sample yet

        sample = TelemetrySample(
            timestamp=now,
            time_boot_ms=pos_msg.time_boot_ms,
            lat=pos_msg.lat / 1e7,
            lon=pos_msg.lon / 1e7,
            alt_relative=pos_msg.relative_alt / 1000.0,
            alt_msl=pos_msg.alt / 1000.0,
            roll=att_msg.roll,
            pitch=att_msg.pitch,
            yaw=att_msg.yaw,
            vx=pos_msg.vx / 100.0,       # cm/s → m/s
            vy=pos_msg.vy / 100.0,
            vz=pos_msg.vz / 100.0,
        )

        with self._lock:
            self._ring.append(sample)

    # -----------------------------------------------------------------
    # COMMAND_ACK processing
    # -----------------------------------------------------------------

    def _process_command_ack(self, msg) -> None:
        """Append a COMMAND_ACK to the queue and wake any waiter."""
        with self._ack_lock:
            self._ack_queue.append(msg)
            self._ack_event.set()
