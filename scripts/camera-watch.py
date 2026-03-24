#!/usr/bin/env python3
"""Watch for camera activity and dim the re-frame gallery brightness."""
import subprocess, time, json, os, sys

# Brightness file is relative to this script's own directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BRIGHTNESS_FILE = os.path.join(SCRIPT_DIR, "..", "gallery", "brightness.json")

LAGO_DIM = 0.65
LAGO_BRIGHT = 1.0

last_state = None


def camera_active():
    """Detect active camera use on macOS.

    Checks for common apps that use the camera:
    - Photo Booth, FaceTime: built-in Apple camera apps
    - CptHost: the process Zoom spawns when camera is active

    Note for Linux users: adapt this function to check /dev/video* activity
    or use v4l2-ctl to detect camera consumers.
    """
    try:
        for name in ["Photo Booth", "FaceTime"]:
            r = subprocess.run(
                ["pgrep", "-x", name], capture_output=True, text=True, timeout=5
            )
            if r.returncode == 0:
                return True
        # Zoom camera host process
        r = subprocess.run(
            ["pgrep", "-x", "CptHost"], capture_output=True, text=True, timeout=5
        )
        if r.returncode == 0:
            return True
        return False
    except Exception:
        return False


def set_brightness(val):
    """Write brightness value to the gallery JSON file."""
    with open(BRIGHTNESS_FILE, "w") as f:
        json.dump({"brightness": val}, f)


def log(msg):
    sys.stdout.write(f"{msg}\n")
    sys.stdout.flush()


log(f"camera-watch started — brightness file: {os.path.normpath(BRIGHTNESS_FILE)}")

while True:
    active = camera_active()

    if active and last_state != "on":
        log("Camera ON — dimming frame")
        set_brightness(LAGO_DIM)

        # Add your smart home integrations here, for example:
        # Elgato Key Light: send PUT to http://<elgato-ip>:9123/elgato/lights
        # Smart plugs: toggle via your home automation API
        # HomeKit / Home Assistant: trigger a scene via webhook

        last_state = "on"

    elif not active and last_state != "off":
        log("Camera OFF — full brightness")
        set_brightness(LAGO_BRIGHT)

        # Restore your smart home integrations here

        last_state = "off"

    time.sleep(5)
