#!/usr/bin/env python3
"""
tests/test_phase1_vehicle.py

Interactive step-by-step validation of the Phase 1 vehicle control layer.

This is NOT an automated unit test.  It runs each vehicle operation in
sequence, prints status, and waits for the human operator to observe the
Gazebo simulation and press Enter to proceed.

Prerequisites
~~~~~~~~~~~~~
1. Gazebo running with ``iris_qr_config3``.
2. ArduPilot SITL running (``sim_vehicle.py … --console --map``).
3. ``MAVLINK_CONNECTION`` set in ``drone_mission/config.py``.

Usage
~~~~~
::

    cd <project root>       # the directory containing drone_mission/
    python tests/test_phase1_vehicle.py

    # OR, as a module:
    python -m tests.test_phase1_vehicle

Safe abort
~~~~~~~~~~
Press **Ctrl+C** at any time.  The script will attempt to command RTL
before exiting.
"""

import logging
import math
import os
import sys
import time

# ---------------------------------------------------------------------------
# Make imports work when running this file directly
# (adds the project root — the parent of tests/ — to sys.path)
# ---------------------------------------------------------------------------
_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PROJECT_ROOT not in sys.path:
    sys.path.insert(0, _PROJECT_ROOT)

from drone_mission.vehicle.pymavlink_vehicle import ArduPilotVehicle

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)-7s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("phase1_test")


# ═══════════════════════════════════════════════════════════════════════════
# Helper utilities
# ═══════════════════════════════════════════════════════════════════════════

def pause(title: str, detail: str = "") -> None:
    """Print a step banner and wait for Enter."""
    print(f"\n{'=' * 64}")
    print(f"  {title}")
    if detail:
        for line in detail.strip().splitlines():
            print(f"    {line}")
    print(f"{'=' * 64}")
    input("  Press ENTER to continue (Ctrl+C to abort) … ")
    print()


def print_telemetry(vehicle: ArduPilotVehicle) -> None:
    """Pretty-print the current vehicle state."""
    pos  = vehicle.get_position()
    att  = vehicle.get_attitude()
    gps  = vehicle.get_gps_status()
    vel  = vehicle.get_velocity()
    mode = vehicle.get_mode()
    armed = vehicle.is_armed()

    print(f"  Mode: {mode}   Armed: {armed}")

    if pos:
        print(f"  Position:  lat={pos.lat:.7f}   lon={pos.lon:.7f}   "
              f"alt_rel={pos.alt_relative:.2f} m   alt_msl={pos.alt_msl:.2f} m")
    else:
        print("  Position:  (not available)")

    if att:
        print(f"  Attitude:  roll={math.degrees(att.roll):+6.1f}°   "
              f"pitch={math.degrees(att.pitch):+6.1f}°   "
              f"yaw={math.degrees(att.yaw):+6.1f}°")
    else:
        print("  Attitude:  (not available)")

    if gps:
        eph_str = f"{gps.eph_m:.2f} m" if gps.eph_m is not None else "N/A"
        epv_str = f"{gps.epv_m:.2f} m" if gps.epv_m is not None else "N/A"
        print(f"  GPS:       fix={gps.fix_type}   sats={gps.satellite_count}   "
              f"eph={eph_str}   epv={epv_str}")
    else:
        print("  GPS:       (not available)")

    if vel:
        speed = math.sqrt(vel.vx**2 + vel.vy**2 + vel.vz**2)
        print(f"  Velocity:  vN={vel.vx:+.2f}   vE={vel.vy:+.2f}   "
              f"vD={vel.vz:+.2f} m/s   |v|={speed:.2f} m/s")
    else:
        print("  Velocity:  (not available)")


def wait_altitude(
    vehicle: ArduPilotVehicle,
    target_m: float,
    fraction: float = 0.90,
    timeout_s: float = 30.0,
) -> bool:
    """Block until relative altitude reaches ``target_m * fraction``."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        pos = vehicle.get_position()
        if pos:
            alt = pos.alt_relative
            pct = (alt / target_m * 100) if target_m != 0 else 0
            print(f"\r  Altitude: {alt:.2f} / {target_m:.1f} m  "
                  f"({pct:.0f}%)    ", end="", flush=True)
            if alt >= target_m * fraction:
                print(f"\n  ✓ Reached {alt:.2f} m "
                      f"(target {target_m:.1f} m)")
                return True
        time.sleep(0.5)
    print(f"\n  ✗ Altitude timeout after {timeout_s:.0f} s")
    return False


def haversine_m(lat1: float, lon1: float,
                lat2: float, lon2: float) -> float:
    """Great-circle distance in metres between two WGS84 coordinates."""
    R = 6_371_000.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1))
         * math.cos(math.radians(lat2))
         * math.sin(dlon / 2) ** 2)
    return R * 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


def wait_arrival(
    vehicle: ArduPilotVehicle,
    lat: float, lon: float,
    radius_m: float = 2.0,
    timeout_s: float = 30.0,
) -> bool:
    """Block until the vehicle is within *radius_m* of *lat, lon*."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        pos = vehicle.get_position()
        if pos:
            dist = haversine_m(pos.lat, pos.lon, lat, lon)
            print(f"\r  Distance to target: {dist:.1f} m    ",
                  end="", flush=True)
            if dist < radius_m:
                print(f"\n  ✓ Arrived (within {radius_m:.0f} m)")
                return True
        time.sleep(0.5)
    print(f"\n  ✗ Arrival timeout after {timeout_s:.0f} s")
    return False


# ═══════════════════════════════════════════════════════════════════════════
# Test sequence
# ═══════════════════════════════════════════════════════════════════════════

def run_test() -> None:
    """Execute the Phase 1 interactive test sequence."""

    vehicle = ArduPilotVehicle()

    try:
        # ── STEP 1  Connect ──────────────────────────────────────────
        pause(
            "STEP 1 — Connect to vehicle",
            "The script will open the MAVLink connection and wait for\n"
            "the first heartbeat from ArduPilot SITL.",
        )
        vehicle.connect()
        print("  ✓ Connected")
        time.sleep(1.5)  # let a few telemetry messages accumulate

        # ── STEP 2  Wait for GPS ─────────────────────────────────────
        pause(
            "STEP 2 — Wait for GPS readiness",
            "SITL needs ~10-20 s after boot for the EKF to converge\n"
            "and GPS to report a 3D fix.  Watch for fix_type and sats.",
        )
        if not vehicle.wait_ready():
            print("  ✗ GPS not ready — aborting test")
            return
        print("  ✓ Vehicle ready")

        # ── STEP 3  Read telemetry ───────────────────────────────────
        pause(
            "STEP 3 — Read and display telemetry",
            "Verify the values look reasonable for the SITL home\n"
            "location (typically near −35.36°, 149.16°).",
        )
        print_telemetry(vehicle)

        home = vehicle.get_home()
        if home:
            print(f"\n  Home position: lat={home.lat:.7f}  "
                  f"lon={home.lon:.7f}")
        else:
            print("\n  Home position: not available yet (will retry later)")

        # ── STEP 4  GUIDED mode ─────────────────────────────────────
        pause(
            "STEP 4 — Set GUIDED mode",
            "Check that MAVProxy/Gazebo shows the mode change.",
        )
        ok = vehicle.set_mode("GUIDED")
        print(f"  set_mode result: {'✓ OK' if ok else '✗ FAILED'}")
        print(f"  Current mode:    {vehicle.get_mode()}")

        # Retry home now that mode is set
        if not home:
            time.sleep(1.5)
            home = vehicle.get_home()
            if home:
                print(f"  Home position:   lat={home.lat:.7f}  "
                      f"lon={home.lon:.7f}")

        # ── STEP 5  Arm ─────────────────────────────────────────────
        pause(
            "STEP 5 — Arm motors",
            "Watch MAVProxy for 'ARMED' and listen for motor spin-up\n"
            "in Gazebo.  If arming fails, check STATUSTEXT output for\n"
            "pre-arm failure reasons.",
        )
        ok = vehicle.arm()
        print(f"  Arm result: {'✓ ARMED' if ok else '✗ FAILED'}")
        if not ok:
            print("  Cannot continue without arming — aborting test.")
            return

        # ── STEP 6  Takeoff ─────────────────────────────────────────
        pause(
            "STEP 6 — Takeoff to 3.5 m",
            "The drone should climb smoothly in Gazebo.\n"
            "Console will print altitude progress.",
        )
        ok = vehicle.takeoff(3.5)
        if not ok:
            print("  ✗ Takeoff command failed — aborting")
            return

        if not wait_altitude(vehicle, 3.5, fraction=0.90, timeout_s=30.0):
            print("  ✗ Did not reach target altitude")

        time.sleep(2.0)  # stabilise at target alt
        print("\n  Post-takeoff telemetry:")
        print_telemetry(vehicle)

        # ── STEP 7  Forward velocity ────────────────────────────────
        pause(
            "STEP 7 — Fly forward at 1 m/s for 3 seconds",
            "Watch the drone translate forward in Gazebo.",
        )
        _stream_velocity(vehicle, vx=1.0, vy=0.0, vz=0.0, duration_s=3.0)
        print("  ✓ Forward movement complete")
        print_telemetry(vehicle)

        # ── STEP 8  Stop ────────────────────────────────────────────
        pause(
            "STEP 8 — Stop and hold position",
            "Drone should decelerate and hover in place.",
        )
        vehicle.stop()
        time.sleep(2.0)
        print_telemetry(vehicle)

        # ── STEP 9  Rightward velocity ──────────────────────────────
        pause(
            "STEP 9 — Fly right at 1 m/s for 3 seconds",
            "Watch the drone translate rightward in Gazebo.",
        )
        _stream_velocity(vehicle, vx=0.0, vy=1.0, vz=0.0, duration_s=3.0)
        print("  ✓ Right movement complete")
        print_telemetry(vehicle)

        # ── STEP 10  Stop ───────────────────────────────────────────
        pause("STEP 10 — Stop and hold position")
        vehicle.stop()
        time.sleep(2.0)
        print_telemetry(vehicle)

        # ── STEP 11  Goto home ──────────────────────────────────────
        if home:
            pause(
                "STEP 11 — Goto near home position",
                f"Target: lat={home.lat:.7f}  lon={home.lon:.7f}  alt=3.5 m\n"
                f"Watch the drone fly back toward home.",
            )
            vehicle.goto(home.lat, home.lon, 3.5)
            wait_arrival(vehicle, home.lat, home.lon,
                         radius_m=2.0, timeout_s=30.0)
            time.sleep(2.0)
            print_telemetry(vehicle)
        else:
            print("\n  STEP 11 — SKIPPED (home position unknown)")

        # ── STEP 12  RTL ────────────────────────────────────────────
        pause(
            "STEP 12 — Return to Launch",
            "Drone should climb to RTL_ALT, fly home, and land.\n"
            "Console will show altitude and armed state until landing.",
        )
        vehicle.rtl()
        print(f"  Mode: {vehicle.get_mode()}")
        print("  Waiting for landing and disarm …")

        deadline = time.time() + 60.0
        landed = False
        while time.time() < deadline:
            pos = vehicle.get_position()
            armed = vehicle.is_armed()
            if pos:
                print(f"\r  Alt: {pos.alt_relative:.2f} m   "
                      f"Armed: {armed}    ", end="", flush=True)
            if not armed:
                print(f"\n  ✓ Disarmed — RTL complete")
                landed = True
                break
            time.sleep(0.5)
        if not landed:
            print(f"\n  ✗ RTL timeout (vehicle still armed after 60 s)")

        # ── STEP 13  Disconnect ─────────────────────────────────────
        pause(
            "STEP 13 — Disconnect",
            "Clean shutdown of background threads and MAVLink transport.",
        )
        vehicle.disconnect()
        print("  ✓ Disconnected cleanly")

        # ── Done ────────────────────────────────────────────────────
        print(f"\n{'═' * 64}")
        print("  PHASE 1 TEST COMPLETE — all steps executed")
        print(f"{'═' * 64}\n")

    except KeyboardInterrupt:
        print("\n\n  ⚠ Ctrl+C — attempting emergency RTL …")
        try:
            vehicle.rtl()
            print("  RTL commanded")
        except Exception:
            pass
        try:
            vehicle.disconnect()
        except Exception:
            pass
        print("  Exiting")
        sys.exit(1)

    except Exception as exc:
        logger.exception("Test failed: %s", exc)
        print(f"\n  ✗ EXCEPTION: {exc}")
        print("    Attempting RTL before exit …")
        try:
            vehicle.rtl()
        except Exception:
            pass
        try:
            vehicle.disconnect()
        except Exception:
            pass
        sys.exit(2)


# ═══════════════════════════════════════════════════════════════════════════
# Velocity streaming helper
# ═══════════════════════════════════════════════════════════════════════════

def _stream_velocity(
    vehicle: ArduPilotVehicle,
    vx: float, vy: float, vz: float,
    duration_s: float,
    rate_hz: float = 10.0,
) -> None:
    """Stream body-velocity commands for *duration_s* seconds at *rate_hz*."""
    interval = 1.0 / rate_hz
    t0 = time.time()
    while time.time() - t0 < duration_s:
        vehicle.send_body_velocity(vx, vy, vz)
        elapsed = time.time() - t0
        print(f"\r  Streaming velocity: "
              f"vx={vx:.1f}  vy={vy:.1f}  vz={vz:.1f}  "
              f"t={elapsed:.1f}/{duration_s:.0f} s    ",
              end="", flush=True)
        time.sleep(interval)
    print()  # newline after \r loop


# ═══════════════════════════════════════════════════════════════════════════
# Entry point
# ═══════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    run_test()
