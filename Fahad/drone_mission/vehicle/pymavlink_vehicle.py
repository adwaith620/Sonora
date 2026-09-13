"""
drone_mission/vehicle/pymavlink_vehicle.py

Concrete VehicleInterface implementation using pymavlink.

Works with both ArduPilot SITL and real Pixhawk hardware — the only
difference between environments is the connection string in config.py.

Threading model
~~~~~~~~~~~~~~~
Three threads are active after ``connect()``:

1. **Main thread** — sends commands, reads cached telemetry.
2. **Telemetry thread** (``TelemetryBuffer``) — drains ``recv_match()``.
3. **Heartbeat thread** — sends heartbeats at 1 Hz.

A ``_send_lock`` serialises all outgoing MAVLink writes so the
heartbeat thread and main thread never interleave wire bytes.

Command acknowledgment
~~~~~~~~~~~~~~~~~~~~~~
``_send_command_long()`` sends a ``COMMAND_LONG`` and polls the
telemetry cache for a matching ``COMMAND_ACK``.  This is adequate for
sequential command use (Phase 1).  If commands are ever pipelined,
replace with a per-command-id queue.
"""

import logging
import math
import threading
import time
from typing import Optional

from pymavlink import mavutil

from drone_mission import config
from drone_mission.interfaces.vehicle import (
    Attitude,
    GPSStatus,
    Position,
    Severity,
    Velocity,
    VehicleInterface,
)
from drone_mission.vehicle.telemetry import TelemetryBuffer

logger = logging.getLogger(__name__)


class ArduPilotVehicle(VehicleInterface):
    """pymavlink vehicle controller for ArduPilot (SITL or Pixhawk).

    Typical usage::

        v = ArduPilotVehicle()
        v.connect()
        v.wait_ready()
        v.set_mode("GUIDED")
        v.arm()
        v.takeoff(3.5)
        ...
        v.rtl()
        v.disconnect()
    """

    def __init__(self) -> None:
        self._master = None
        self._telemetry: Optional[TelemetryBuffer] = None

        self._heartbeat_thread: Optional[threading.Thread] = None
        self._hb_running: bool = False

        # Serialises all mav.*_send() calls across threads
        self._send_lock = threading.Lock()

        # mode_name -> mode_id,  mode_id -> mode_name
        self._mode_map: dict = {}
        self._mode_map_inv: dict = {}

    # =====================================================================
    # Connection / Lifecycle
    # =====================================================================

    def connect(self) -> None:
        conn_str = config.MAVLINK_CONNECTION
        if conn_str == "ENTER_CONNECTION_HERE":
            raise ConnectionError(
                "MAVLINK_CONNECTION is not configured.  "
                "Edit drone_mission/config.py and set it to your "
                "MAVLink endpoint (e.g. 'tcp:127.0.0.1:5760')."
            )

        logger.info("Connecting to %s …", conn_str)
        self._master = mavutil.mavlink_connection(
            conn_str,
            autoreconnect=True,
            source_system=config.SOURCE_SYSTEM,
            source_component=config.SOURCE_COMPONENT,
        )

        # Wait for the autopilot's first heartbeat
        logger.info("Waiting for heartbeat …")
        hb = self._master.wait_heartbeat(timeout=config.HEARTBEAT_TIMEOUT_S)
        if hb is None:
            raise ConnectionError("No heartbeat received from vehicle")

        logger.info(
            "Heartbeat OK — target_system=%d  target_component=%d",
            self._master.target_system,
            self._master.target_component,
        )

        # Build mode name ↔ id mapping from the vehicle type
        raw = self._master.mode_mapping()
        if isinstance(raw, dict):
            self._mode_map = raw
            self._mode_map_inv = {v: k for k, v in raw.items()}
        else:
            logger.warning("mode_mapping() returned non-dict: %s", type(raw))
            self._mode_map = {}
            self._mode_map_inv = {}

        # Start telemetry receive thread
        self._telemetry = TelemetryBuffer(self._master)
        self._telemetry.start()

        # Start heartbeat transmit thread
        self._hb_running = True
        self._heartbeat_thread = threading.Thread(
            target=self._heartbeat_loop,
            name="heartbeat-tx",
            daemon=True,
        )
        self._heartbeat_thread.start()

        logger.info("Connection established — telemetry and heartbeat active")

    def disconnect(self) -> None:
        logger.info("Disconnecting …")

        # Stop heartbeat thread
        self._hb_running = False
        if self._heartbeat_thread is not None:
            self._heartbeat_thread.join(timeout=3.0)
            self._heartbeat_thread = None

        # Stop telemetry thread
        if self._telemetry is not None:
            self._telemetry.stop()
            self._telemetry = None

        # Close the MAVLink transport
        if self._master is not None:
            self._master.close()
            self._master = None

        logger.info("Disconnected")

    def wait_ready(self, timeout: float = None) -> bool:
        if timeout is None:
            timeout = config.GPS_STARTUP_TIMEOUT_S

        logger.info(
            "Waiting for GPS fix type >= %d …",
            config.GPS_FIX_TYPE_REQUIRED,
        )

        deadline = time.time() + timeout
        while time.time() < deadline:
            gps = self.get_gps_status()
            if gps is not None:
                if gps.fix_type >= config.GPS_FIX_TYPE_REQUIRED:
                    logger.info(
                        "GPS ready — fix=%d  sats=%d  eph=%.2f m  epv=%.2f m",
                        gps.fix_type, gps.satellite_count,
                        gps.eph_m if gps.eph_m is not None else -1.0,
                        gps.epv_m if gps.epv_m is not None else -1.0,
                    )
                    return True
                logger.debug(
                    "GPS settling — fix=%d  sats=%d",
                    gps.fix_type, gps.satellite_count,
                )
            time.sleep(0.5)

        logger.error("GPS fix timeout after %.0f s", timeout)
        return False

    # =====================================================================
    # Telemetry
    # =====================================================================

    def get_position(self) -> Optional[Position]:
        msg = self._telemetry.get_message("GLOBAL_POSITION_INT")
        if msg is None:
            return None
        return Position(
            lat=msg.lat / 1e7,
            lon=msg.lon / 1e7,
            alt_relative=msg.relative_alt / 1000.0,   # mm → m
            alt_msl=msg.alt / 1000.0,                  # mm → m
            timestamp=time.time(),
        )

    def get_attitude(self) -> Optional[Attitude]:
        msg = self._telemetry.get_message("ATTITUDE")
        if msg is None:
            return None
        return Attitude(
            roll=msg.roll,       # already radians
            pitch=msg.pitch,
            yaw=msg.yaw,
            timestamp=time.time(),
        )

    def get_gps_status(self) -> Optional[GPSStatus]:
        msg = self._telemetry.get_message("GPS_RAW_INT")
        if msg is None:
            return None
        # GPS_RAW_INT.eph: estimated horizontal position error, uint16,
        # units = centimetres.  A value of 0 means "unavailable".
        # GPS_RAW_INT.epv: estimated vertical position error, uint16,
        # units = centimetres.  A value of 0 means "unavailable".
        return GPSStatus(
            fix_type=msg.fix_type,
            satellite_count=msg.satellites_visible,
            eph_m=msg.eph / 100.0 if msg.eph != 0 else None,   # cm → m
            epv_m=msg.epv / 100.0 if msg.epv != 0 else None,   # cm → m
        )

    def get_velocity(self) -> Optional[Velocity]:
        msg = self._telemetry.get_message("GLOBAL_POSITION_INT")
        if msg is None:
            return None
        return Velocity(
            vx=msg.vx / 100.0,   # cm/s → m/s
            vy=msg.vy / 100.0,
            vz=msg.vz / 100.0,
        )

    def is_armed(self) -> bool:
        if self._telemetry is None:
            return False
        return self._telemetry.armed

    def get_mode(self) -> Optional[str]:
        if self._telemetry is None:
            return None
        mode_id = self._telemetry.mode_id
        if mode_id is None:
            return None
        return self._mode_map_inv.get(mode_id, f"UNKNOWN_{mode_id}")

    def get_home(self) -> Optional[Position]:
        if self._telemetry is None:
            return None

        msg = self._telemetry.get_message("HOME_POSITION")
        if msg is None:
            # Actively request it — ArduPilot doesn't always broadcast it
            logger.debug("Requesting HOME_POSITION …")
            self._send_command_long(
                mavutil.mavlink.MAV_CMD_GET_HOME_POSITION
            )
            time.sleep(1.0)
            msg = self._telemetry.get_message("HOME_POSITION")
            if msg is None:
                return None

        return Position(
            lat=msg.latitude / 1e7,
            lon=msg.longitude / 1e7,
            alt_relative=0.0,                 # Home is the altitude reference
            alt_msl=msg.altitude / 1000.0,    # mm → m
        )

    # =====================================================================
    # Flight Commands
    # =====================================================================

    def set_mode(self, mode: str) -> bool:
        mode_upper = mode.upper()
        if mode_upper not in self._mode_map:
            logger.error(
                "Unknown mode '%s'.  Available: %s",
                mode_upper, list(self._mode_map.keys()),
            )
            return False

        mode_id = self._mode_map[mode_upper]
        logger.info("Setting mode → %s (id %d) …", mode_upper, mode_id)

        # master.set_mode() sends a SET_MODE message (not COMMAND_LONG),
        # so there is no COMMAND_ACK.  We verify by polling heartbeat.
        with self._send_lock:
            self._master.set_mode(mode_id)

        deadline = time.time() + config.COMMAND_ACK_TIMEOUT_S
        while time.time() < deadline:
            if self.get_mode() == mode_upper:
                logger.info("Mode confirmed: %s", mode_upper)
                return True
            time.sleep(0.1)

        logger.error("Mode change to %s not confirmed within timeout", mode_upper)
        return False

    def arm(self) -> bool:
        logger.info("Arming motors …")

        # param2: 0 = normal arming,  21196 = force (bypasses pre-arm)
        param2 = 21196.0 if config.FORCE_ARM else 0.0

        accepted = self._send_command_long(
            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
            param1=1.0,
            param2=param2,
        )
        if not accepted:
            logger.error("Arm command not accepted (check STATUSTEXT for reason)")
            return False

        # Wait for armed flag in heartbeat
        deadline = time.time() + config.ARM_TIMEOUT_S
        while time.time() < deadline:
            if self.is_armed():
                logger.info("Motors ARMED")
                return True
            time.sleep(0.1)

        logger.error("Arm timeout — vehicle did not arm")
        return False

    def disarm(self) -> bool:
        logger.info("Disarming motors …")

        accepted = self._send_command_long(
            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
            param1=0.0,
        )
        if not accepted:
            logger.error("Disarm command not accepted")
            return False

        deadline = time.time() + config.COMMAND_ACK_TIMEOUT_S
        while time.time() < deadline:
            if not self.is_armed():
                logger.info("Motors DISARMED")
                return True
            time.sleep(0.1)

        logger.error("Disarm not confirmed within timeout")
        return False

    def takeoff(self, altitude_m: float) -> bool:
        """Send takeoff command.

        Requires: GUIDED mode, armed.
        Returns True if the command was accepted.
        Does NOT block until altitude is reached.
        """
        logger.info("Commanding takeoff to %.1f m …", altitude_m)

        accepted = self._send_command_long(
            mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
            param7=altitude_m,    # target altitude, relative to home
        )

        if accepted:
            logger.info("Takeoff command accepted (target %.1f m)", altitude_m)
        else:
            logger.error("Takeoff command rejected or no ACK")

        return accepted

    def goto(self, lat: float, lon: float, alt_m: float) -> None:
        """Send a global position target.  Non-blocking."""

        # type_mask: use position only, ignore velocity / accel / yaw
        type_mask = (
            mavutil.mavlink.POSITION_TARGET_TYPEMASK_VX_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_VY_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_VZ_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_AX_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_AY_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_AZ_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_YAW_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_YAW_RATE_IGNORE
        )  # = 3576 = 0x0DF8

        with self._send_lock:
            self._master.mav.set_position_target_global_int_send(
                0,                  # time_boot_ms (0 → autopilot uses its own)
                self._master.target_system,
                self._master.target_component,
                mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT_INT,  # frame 6
                type_mask,
                int(lat * 1e7),     # lat_int: degrees × 1e7
                int(lon * 1e7),     # lon_int: degrees × 1e7
                float(alt_m),       # alt: metres, relative to home
                0, 0, 0,            # vx, vy, vz  (ignored by type_mask)
                0, 0, 0,            # afx, afy, afz (ignored)
                0, 0,               # yaw, yaw_rate (ignored)
            )

        logger.debug(
            "goto → lat=%.7f  lon=%.7f  alt=%.1f m", lat, lon, alt_m,
        )

    def send_body_velocity(self, vx: float, vy: float, vz: float) -> None:
        """Send one body-frame velocity command.

        Body-frame (MAV_FRAME_BODY_NED):
            vx > 0 → forward,  vy > 0 → right,  vz > 0 → descend

        The caller MUST loop at ``config.VELOCITY_CMD_RATE_HZ``.
        """

        # type_mask: use velocity only, ignore position / accel / yaw
        type_mask = (
            mavutil.mavlink.POSITION_TARGET_TYPEMASK_X_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_Y_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_Z_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_AX_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_AY_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_AZ_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_YAW_IGNORE
            | mavutil.mavlink.POSITION_TARGET_TYPEMASK_YAW_RATE_IGNORE
        )  # = 3527 = 0x0DC7

        with self._send_lock:
            self._master.mav.set_position_target_local_ned_send(
                0,                  # time_boot_ms
                self._master.target_system,
                self._master.target_component,
                mavutil.mavlink.MAV_FRAME_BODY_NED,   # frame 8
                type_mask,
                0, 0, 0,            # x, y, z position (ignored)
                float(vx),          # forward  m/s
                float(vy),          # right    m/s
                float(vz),          # down     m/s
                0, 0, 0,            # afx, afy, afz (ignored)
                0, 0,               # yaw, yaw_rate (ignored)
            )

    def stop(self) -> None:
        """Send zero velocity to halt.  Single-shot, non-blocking.

        Sends a few zero-velocity commands to ensure ArduPilot receives
        the stop intent even if a single packet is dropped.
        """
        logger.info("Commanding stop (zero-velocity hold)")
        for _ in range(3):
            self.send_body_velocity(0.0, 0.0, 0.0)
            time.sleep(0.05)

    def stop_and_hold(self, timeout: float = None) -> bool:
        """Send zero velocity and wait until ground speed drops below
        ``config.STOP_SPEED_THRESHOLD_MS``.

        Args:
            timeout: Max seconds to wait.  Defaults to
                     ``config.STOP_HOLD_TIMEOUT_S``.

        Returns:
            True if vehicle speed fell below threshold; False on timeout.
        """
        if timeout is None:
            timeout = config.STOP_HOLD_TIMEOUT_S

        self.stop()

        deadline = time.time() + timeout
        while time.time() < deadline:
            vel = self.get_velocity()
            if vel is not None:
                ground_speed = math.sqrt(vel.vx ** 2 + vel.vy ** 2)
                if ground_speed < config.STOP_SPEED_THRESHOLD_MS:
                    logger.info(
                        "Vehicle stopped (speed %.2f m/s < %.2f threshold)",
                        ground_speed, config.STOP_SPEED_THRESHOLD_MS,
                    )
                    return True
            # Keep sending zero velocity while waiting
            self.send_body_velocity(0.0, 0.0, 0.0)
            time.sleep(0.1)

        logger.warning("stop_and_hold timeout after %.1f s", timeout)
        return False

    def rtl(self) -> None:
        logger.info("Commanding RTL")
        self.set_mode("RTL")

    # =====================================================================
    # GCS Reporting
    # =====================================================================

    def send_statustext(
        self,
        text: str,
        severity: Severity = Severity.INFO,
    ) -> None:
        # MAVLink v1 STATUSTEXT is limited to 50 chars
        truncated = text[:50]
        with self._send_lock:
            self._master.mav.statustext_send(
                int(severity),
                truncated.encode("utf-8"),
            )
        logger.info("STATUSTEXT [%s]: %s", severity.name, truncated)

    # =====================================================================
    # Internal helpers
    # =====================================================================

    def _send_command_long(
        self,
        command_id: int,
        param1: float = 0.0,
        param2: float = 0.0,
        param3: float = 0.0,
        param4: float = 0.0,
        param5: float = 0.0,
        param6: float = 0.0,
        param7: float = 0.0,
        confirmation: int = 0,
    ) -> bool:
        """Send a COMMAND_LONG and wait for COMMAND_ACK.

        Returns ``True`` if ``MAV_RESULT_ACCEPTED`` is received.

        Uses the TelemetryBuffer's public ACK API:
        1. ``clear_command_acks()`` — discard stale ACKs.
        2. Send the COMMAND_LONG.
        3. ``wait_command_ack(command_id)`` — block until a matching ACK
           arrives or timeout expires.

        This is correct for Phase 1's sequential command flow.
        """
        # Clear stale ACKs before sending
        self._telemetry.clear_command_acks()

        with self._send_lock:
            self._master.mav.command_long_send(
                self._master.target_system,
                self._master.target_component,
                command_id,
                confirmation,
                param1, param2, param3, param4,
                param5, param6, param7,
            )

        # Wait for matching ACK via the public telemetry API
        result = self._telemetry.wait_command_ack(
            command_id, timeout=config.COMMAND_ACK_TIMEOUT_S
        )

        if result is None:
            logger.warning(
                "No COMMAND_ACK for cmd=%d within %.1f s",
                command_id, config.COMMAND_ACK_TIMEOUT_S,
            )
            return False

        if result == mavutil.mavlink.MAV_RESULT_ACCEPTED:
            logger.debug("COMMAND_ACK: cmd=%d  result=ACCEPTED", command_id)
            return True
        else:
            logger.warning(
                "COMMAND_ACK: cmd=%d  result=%d", command_id, result
            )
            return False

    def _heartbeat_loop(self) -> None:
        """Background thread: send GCS heartbeats at 1 Hz.

        Prevents ArduPilot's GCS-failsafe from triggering when a
        companion computer is the only MAVLink peer.
        """
        interval = 1.0 / config.HEARTBEAT_RATE_HZ
        while self._hb_running:
            try:
                with self._send_lock:
                    self._master.mav.heartbeat_send(
                        mavutil.mavlink.MAV_TYPE_GCS,           # type 6
                        mavutil.mavlink.MAV_AUTOPILOT_INVALID,  # autopilot 8
                        0,                                      # base_mode
                        0,                                      # custom_mode
                        mavutil.mavlink.MAV_STATE_ACTIVE,       # state 4
                    )
            except Exception as e:
                if self._hb_running:
                    logger.warning("Heartbeat send error: %s", e)
            time.sleep(interval)
