"""
drone_mission/interfaces/vehicle.py

Abstract Vehicle Interface and telemetry data structures.

All mission code programs against VehicleInterface.
Concrete implementations (pymavlink for SITL / Pixhawk) live in vehicle/.

This file also defines the dataclasses for telemetry snapshots.
They are plain frozen dataclasses with no MAVLink dependency — usable
anywhere in the codebase without importing pymavlink.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import IntEnum
from typing import Optional


# =============================================================================
# Telemetry Data Structures
# =============================================================================

@dataclass(frozen=True)
class Position:
    """Vehicle position snapshot.

    Attributes:
        lat:          Latitude in degrees (WGS84).
        lon:          Longitude in degrees (WGS84).
        alt_relative: Altitude in metres, relative to home / takeoff point.
                      This is the primary altitude reference in Phase 1.
        alt_msl:      Altitude in metres above mean sea level.
                      May be None if unavailable.
        timestamp:    Measurement time as time.time() epoch seconds.
    """
    lat: float
    lon: float
    alt_relative: float
    alt_msl: Optional[float] = None
    timestamp: float = 0.0


@dataclass(frozen=True)
class Attitude:
    """Vehicle attitude in the NED body frame.

    All angles are in **radians**.

    Attributes:
        roll:      Roll angle, –π to +π (positive = right wing down).
        pitch:     Pitch angle, –π to +π (positive = nose up).
        yaw:       Yaw angle, –π to +π (0 = geographic North, positive = clockwise).
        timestamp: Measurement time as time.time() epoch seconds.
    """
    roll: float
    pitch: float
    yaw: float
    timestamp: float = 0.0


@dataclass(frozen=True)
class GPSStatus:
    """GPS fix quality.

    Attributes:
        fix_type:        0 = no fix, 2 = 2D, 3 = 3D, 4 = DGPS,
                         5 = RTK float, 6 = RTK fixed.
        satellite_count: Number of visible satellites.
        eph_m:           Estimated horizontal position error in **metres**.
                         Converted from GPS_RAW_INT.eph which is uint16 in
                         centimetres.  None if the field is zero / unavailable.
        epv_m:           Estimated vertical position error in **metres**.
                         Converted from GPS_RAW_INT.epv which is uint16 in
                         centimetres.  None if the field is zero / unavailable.
    """
    fix_type: int
    satellite_count: int
    eph_m: Optional[float] = None
    epv_m: Optional[float] = None


@dataclass(frozen=True)
class Velocity:
    """Vehicle ground velocity in the NED frame.

    Attributes:
        vx: North velocity in m/s.
        vy: East velocity in m/s.
        vz: Down velocity in m/s (positive = descending).
    """
    vx: float
    vy: float
    vz: float


class Severity(IntEnum):
    """MAVLink STATUSTEXT severity levels (MAV_SEVERITY).

    Matches the MAVLink enum so the integer value can be passed
    directly to statustext_send().
    """
    EMERGENCY = 0
    ALERT     = 1
    CRITICAL  = 2
    ERROR     = 3
    WARNING   = 4
    NOTICE    = 5
    INFO      = 6
    DEBUG     = 7


# =============================================================================
# Abstract Vehicle Interface
# =============================================================================

class VehicleInterface(ABC):
    """Abstract interface that all vehicle implementations must satisfy.

    Mission code calls only these methods. The concrete implementation
    handles MAVLink serialisation, threading, and transport details.

    Design rules:
    - No MAVLink types appear in this interface.
    - Blocking waits belong in the caller, not here (except connect/wait_ready).
    - send_body_velocity() is single-shot; the caller must loop.
    - goto() is non-blocking; the caller polls for arrival.
    """

    # -----------------------------------------------------------------
    # Connection / Lifecycle
    # -----------------------------------------------------------------

    @abstractmethod
    def connect(self) -> None:
        """Establish the MAVLink connection and wait for initial heartbeat.

        Starts background threads for telemetry reception and heartbeat
        transmission.

        Raises:
            ConnectionError: If connection or heartbeat times out.
        """
        ...

    @abstractmethod
    def disconnect(self) -> None:
        """Cleanly shut down: stop threads, close transport."""
        ...

    @abstractmethod
    def wait_ready(self, timeout: float = 60.0) -> bool:
        """Block until the vehicle is flight-ready.

        "Ready" means: GPS fix type >= configured minimum
        (``config.GPS_FIX_TYPE_REQUIRED``).  GPS accuracy metrics
        (EPH/EPV) are logged but do not gate readiness in Phase 1.

        Args:
            timeout: Maximum seconds to wait.

        Returns:
            True if the vehicle is ready; False on timeout.
        """
        ...

    # -----------------------------------------------------------------
    # Telemetry (read latest cached values)
    # -----------------------------------------------------------------

    @abstractmethod
    def get_position(self) -> Optional[Position]:
        """Latest position. Altitude is relative to home.

        Returns None if no GLOBAL_POSITION_INT has been received yet.
        """
        ...

    @abstractmethod
    def get_attitude(self) -> Optional[Attitude]:
        """Latest attitude (roll / pitch / yaw in radians).

        Returns None if no ATTITUDE message has been received yet.
        """
        ...

    @abstractmethod
    def get_gps_status(self) -> Optional[GPSStatus]:
        """GPS fix quality information.

        Returns None if no GPS_RAW_INT has been received yet.
        """
        ...

    @abstractmethod
    def get_velocity(self) -> Optional[Velocity]:
        """Latest ground velocity in NED m/s.

        Returns None if not yet available.
        """
        ...

    @abstractmethod
    def is_armed(self) -> bool:
        """True if the motors are armed (from the latest HEARTBEAT)."""
        ...

    @abstractmethod
    def get_mode(self) -> Optional[str]:
        """Current flight mode as an uppercase string (e.g. 'GUIDED').

        Returns None if mode has not been determined yet.
        """
        ...

    @abstractmethod
    def get_home(self) -> Optional[Position]:
        """Home / launch position.

        May actively request HOME_POSITION from the autopilot if it
        has not been received yet.

        Returns None if unavailable.
        """
        ...

    # -----------------------------------------------------------------
    # Flight Commands
    # -----------------------------------------------------------------

    @abstractmethod
    def set_mode(self, mode: str) -> bool:
        """Change the flight mode.

        Args:
            mode: Mode name string, e.g. "GUIDED", "RTL", "LAND", "LOITER".

        Returns:
            True if the mode change is confirmed.
        """
        ...

    @abstractmethod
    def arm(self) -> bool:
        """Arm motors.  Requires GUIDED mode and passed pre-arm checks.

        Returns True if arming is confirmed.
        """
        ...

    @abstractmethod
    def disarm(self) -> bool:
        """Disarm motors.  Returns True if confirmed."""
        ...

    @abstractmethod
    def takeoff(self, altitude_m: float) -> bool:
        """Command takeoff to a target altitude (metres, relative to home).

        Returns True if the takeoff command was *accepted* by the autopilot.
        Does **not** block until the altitude is reached — the caller must
        poll ``get_position().alt_relative``.
        """
        ...

    @abstractmethod
    def goto(self, lat: float, lon: float, alt_m: float) -> None:
        """Send a global position target (non-blocking).

        The vehicle begins navigating toward the target.  The caller
        must poll ``get_position()`` to determine arrival.

        Args:
            lat:   Target latitude in degrees.
            lon:   Target longitude in degrees.
            alt_m: Target altitude in metres, relative to home.
        """
        ...

    @abstractmethod
    def send_body_velocity(self, vx: float, vy: float, vz: float) -> None:
        """Send a **single** body-frame velocity command.

        Body-frame convention (ArduPilot):
            vx > 0 → forward
            vy > 0 → right
            vz > 0 → descend

        MUST be called repeatedly at ``config.VELOCITY_CMD_RATE_HZ``.
        ArduPilot stops the vehicle if velocity commands stop arriving
        (governed by the GUID_TIMEOUT parameter, typically 3 s).
        """
        ...

    @abstractmethod
    def stop(self) -> None:
        """Send zero velocity to halt.  Single-shot, non-blocking."""
        ...

    @abstractmethod
    def stop_and_hold(self, timeout: float = 5.0) -> bool:
        """Send zero velocity and wait until ground speed drops below
        ``config.STOP_SPEED_THRESHOLD_MS``.

        Useful during state transitions where the mission must confirm
        the vehicle has actually stopped before proceeding.

        Args:
            timeout: Maximum seconds to wait for deceleration.

        Returns:
            True if vehicle speed fell below threshold; False on timeout.
        """
        ...

    @abstractmethod
    def rtl(self) -> None:
        """Command Return to Launch (switches to RTL mode)."""
        ...

    # -----------------------------------------------------------------
    # GCS Reporting
    # -----------------------------------------------------------------

    @abstractmethod
    def send_statustext(self, text: str,
                        severity: Severity = Severity.INFO) -> None:
        """Send a STATUSTEXT message to the Ground Control Station.

        Args:
            text:     Message text.  Will be truncated to 50 chars for
                      MAVLink v1 compatibility.
            severity: Message severity (default INFO).
        """
        ...
