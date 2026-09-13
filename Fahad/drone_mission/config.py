"""
drone_mission/config.py

Central configuration for the QR-searching quadcopter mission.
All tuneable parameters live here — no magic numbers scattered in code.

Each section is labelled with the phase that first uses it.
Parameters added in later phases will be appended to the relevant section.
"""

# =============================================================================
# MAVLink Connection  [Phase 1]
# =============================================================================

# *** MUST be set before running. ***
#
# Examples:
#   "tcp:127.0.0.1:5760"      — Direct SITL TCP (sim_vehicle.py default)
#   "udpin:0.0.0.0:14550"     — MAVProxy-forwarded UDP
#   "/dev/ttyACM0,115200"     — Real Pixhawk over USB serial
#   "/dev/ttyAMA0,921600"     — Real Pixhawk over UART (RPi 5 GPIO)
MAVLINK_CONNECTION = "ENTER_CONNECTION_HERE"

# MAVLink system / component IDs for this companion computer.
# 255 is the conventional GCS / companion system ID.
SOURCE_SYSTEM = 255
SOURCE_COMPONENT = 0

# =============================================================================
# Heartbeat  [Phase 1]
# =============================================================================

# Rate at which this script sends heartbeats to the autopilot.
# Prevents ArduPilot GCS-failsafe from triggering.
HEARTBEAT_RATE_HZ = 1.0

# If no vehicle heartbeat arrives within this window, declare connection lost.
HEARTBEAT_TIMEOUT_S = 5.0

# =============================================================================
# Startup / Readiness  [Phase 1]
# =============================================================================

# Minimum GPS fix type before the vehicle is considered flight-ready.
#   0-1 = no fix,  2 = 2D,  3 = 3D,  4 = DGPS,  5 = RTK float,  6 = RTK fixed
GPS_FIX_TYPE_REQUIRED = 3

# NOTE: GPS_RAW_INT.eph is *estimated horizontal position error* (in cm),
# NOT HDOP.  We do NOT gate Phase 1 readiness on an EPH threshold because
# SITL values vary and an arbitrary gate blocks testing.  EPH/EPV are
# logged and available to higher layers for error budgets (Phase 13).

# Maximum time to wait for GPS fix during startup.
GPS_STARTUP_TIMEOUT_S = 60.0

# =============================================================================
# Arming  [Phase 1]
# =============================================================================

# Maximum time to wait for arm confirmation after sending the arm command.
ARM_TIMEOUT_S = 30.0

# If True, send param2=21196 to bypass pre-arm checks.
# ** DEBUG / SITL ONLY — never enable on a real aircraft **
FORCE_ARM = False

# =============================================================================
# Takeoff  [Phase 1]
# =============================================================================

# Fraction of target altitude at which takeoff is considered complete.
# e.g. 0.95 means 95% of the commanded altitude.
TAKEOFF_COMPLETE_FRAC = 0.95

# Maximum time to wait for takeoff to reach target altitude.
TAKEOFF_TIMEOUT_S = 30.0

# =============================================================================
# Navigation  [Phase 1]
# =============================================================================

# Waypoint is considered "reached" when horizontal distance is within this.
GOTO_ACCEPT_RADIUS_M = 1.0

# Maximum time allowed for a single goto command.
GOTO_TIMEOUT_S = 60.0

# =============================================================================
# Velocity Control  [Phase 1]
# =============================================================================

# Refresh rate for streaming velocity commands.
# Must be faster than ArduPilot's GUID_TIMEOUT (default 3.0 s).
# 10 Hz is conservative and responsive.
VELOCITY_CMD_RATE_HZ = 10.0

# stop_and_hold() considers the vehicle "stopped" when ground speed
# is below this threshold (m/s).
STOP_SPEED_THRESHOLD_MS = 0.3

# Maximum time stop_and_hold() will wait for the vehicle to decelerate.
STOP_HOLD_TIMEOUT_S = 5.0

# =============================================================================
# Telemetry  [Phase 1]
# =============================================================================

# Number of timestamped samples retained in the ring buffer.
# At ~10 Hz position rate, 500 samples ≈ 50 seconds of history.
# Used by Phase 12 georeferencing for time-aligned lookups.
TELEMETRY_RING_BUFFER_SIZE = 500

# =============================================================================
# Altitude Reference  [Phase 1]
# =============================================================================

# Phase 1 uses RELATIVE_HOME exclusively.
# This constant documents the assumption. Later phases will add
# terrain-relative or MSL modes here, and the vehicle layer will
# convert as needed.
#
# Options: "RELATIVE_HOME", "MSL", "TERRAIN"
ALTITUDE_REFERENCE = "RELATIVE_HOME"

# =============================================================================
# Command Acknowledgment  [Phase 1]
# =============================================================================

# Maximum time to wait for a COMMAND_ACK from the autopilot.
COMMAND_ACK_TIMEOUT_S = 5.0
