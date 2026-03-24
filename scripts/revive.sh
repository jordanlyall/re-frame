#!/usr/bin/env bash
# revive.sh — Interactive ADB frame revival using a device profile
# Usage: revive.sh <device-profile-name>

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}[ok]${RESET} $*"; }
skip() { echo -e "${YELLOW}[skip]${RESET} $*"; }
err()  { echo -e "${RED}[error]${RESET} $*" >&2; }

# --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: revive.sh <device-profile-name>

Interactively revive a bricked digital frame using an ADB device profile.

Arguments:
  device-profile-name   Name of a profile in the devices/ directory (without .json)

Examples:
  revive.sh lago-genesis

Steps performed:
  1. Connect to device via ADB over Wi-Fi
  2. Remove dead launcher packages
  3. Configure always-on display settings
  4. Install Fully Kiosk Browser APK (optional)
  5. Set default launcher

Requirements:
  adb    Android Debug Bridge (https://developer.android.com/tools/adb)
  python3 For JSON profile parsing
EOF
  exit 0
fi

# Require a profile name
if [[ $# -lt 1 ]]; then
  err "No device profile specified."
  echo "Usage: revive.sh <device-profile-name>   (or --help)"
  exit 1
fi

PROFILE_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_PATH="$SCRIPT_DIR/../devices/${PROFILE_NAME}.json"

# Resolve to absolute path
PROFILE_PATH="$(cd "$(dirname "$PROFILE_PATH")" && pwd)/$(basename "$PROFILE_PATH")"

# Check dependencies
for cmd in adb python3; do
  if ! command -v "$cmd" &>/dev/null; then
    err "'$cmd' is not installed or not in PATH. Please install it and try again."
    exit 1
  fi
done

# Load profile
if [[ ! -f "$PROFILE_PATH" ]]; then
  err "Profile not found: $PROFILE_PATH"
  echo "Available profiles:"
  ls "$SCRIPT_DIR/../devices/"*.json 2>/dev/null | xargs -I{} basename {} .json | sed 's/^/  /'
  exit 1
fi

# Parse profile fields
DEVICE_NAME=$(python3 -c "import json,sys; d=json.load(open('$PROFILE_PATH')); print(d['name'])")
MANUFACTURER=$(python3 -c "import json,sys; d=json.load(open('$PROFILE_PATH')); print(d.get('manufacturer','Unknown'))")
STATUS=$(python3 -c "import json,sys; d=json.load(open('$PROFILE_PATH')); print(d.get('status','unknown'))")
ADB_NOTES=$(python3 -c "import json,sys; d=json.load(open('$PROFILE_PATH')); print(d['revival'].get('adb_notes',''))")
RECOMMENDED_LAUNCHER=$(python3 -c "import json,sys; d=json.load(open('$PROFILE_PATH')); print(d['revival'].get('recommended_launcher',''))")

# Dead packages as newline-separated list
DEAD_PACKAGES=$(python3 -c "
import json, sys
d = json.load(open('$PROFILE_PATH'))
for p in d['revival'].get('dead_packages', []):
    print(p)
")

# Track what was done
DONE=()

# Header
echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD} Re-Frame Revival${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo -e "  Device:       ${BOLD}${DEVICE_NAME}${RESET}"
echo -e "  Manufacturer: ${MANUFACTURER}"
echo -e "  Status:       ${STATUS}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# ── Step 1: ADB connect ────────────────────────────────────────────────────────
echo -e "${BOLD}Step 1: Connect via ADB over Wi-Fi${RESET}"
read -rp "  Enter device IP address: " DEVICE_IP
if [[ -z "$DEVICE_IP" ]]; then
  skip "No IP entered. Skipping ADB connect."
else
  echo "  Running: adb connect ${DEVICE_IP}:5555"
  if adb connect "${DEVICE_IP}:5555"; then
    ok "Connected to ${DEVICE_IP}:5555"
    DONE+=("Connected to ${DEVICE_IP}:5555")
  else
    err "ADB connect failed. Check device IP and that wireless debugging is enabled."
    read -rp "  Continue anyway? (y/n): " CONT
    [[ "$CONT" != "y" ]] && exit 1
  fi
fi
echo ""

# ── Step 2: Remove dead packages ──────────────────────────────────────────────
echo -e "${BOLD}Step 2: Remove dead launcher packages${RESET}"
if [[ -z "$DEAD_PACKAGES" ]]; then
  skip "No dead packages listed in profile."
else
  echo "  Packages to remove:"
  while IFS= read -r pkg; do
    echo "    - $pkg"
  done <<< "$DEAD_PACKAGES"
  read -rp "  Remove dead launcher packages? (y/n): " DO_REMOVE
  if [[ "$DO_REMOVE" == "y" ]]; then
    while IFS= read -r pkg; do
      echo "  Running: adb shell pm uninstall -k --user 0 $pkg"
      if adb shell pm uninstall -k --user 0 "$pkg" 2>&1; then
        ok "Removed $pkg"
        DONE+=("Removed package: $pkg")
      else
        err "Failed to remove $pkg (may already be absent)"
      fi
    done <<< "$DEAD_PACKAGES"
  else
    skip "Skipping package removal."
  fi
fi
echo ""

# ── Step 3: Always-on display ─────────────────────────────────────────────────
echo -e "${BOLD}Step 3: Configure always-on display${RESET}"
echo "  Will run:"
echo "    adb shell settings put global stay_on_while_plugged_in 3"
echo "    adb shell settings put system screen_off_timeout 2147483647"
echo "    adb shell settings put global policy_control immersive.full=*"
read -rp "  Configure always-on display? (y/n): " DO_AOD
if [[ "$DO_AOD" == "y" ]]; then
  adb shell settings put global stay_on_while_plugged_in 3
  ok "stay_on_while_plugged_in = 3"
  adb shell settings put system screen_off_timeout 2147483647
  ok "screen_off_timeout = 2147483647"
  adb shell settings put global policy_control immersive.full='*'
  ok "policy_control = immersive.full=*"
  DONE+=("Configured always-on display")
else
  skip "Skipping always-on display configuration."
fi
echo ""

# ── Step 4: Install Fully Kiosk Browser ───────────────────────────────────────
echo -e "${BOLD}Step 4: Install Fully Kiosk Browser${RESET}"
read -rp "  Provide APK path (or press Enter to skip): " APK_PATH
if [[ -z "$APK_PATH" ]]; then
  skip "Skipping Fully Kiosk Browser install."
else
  if [[ ! -f "$APK_PATH" ]]; then
    err "APK not found at: $APK_PATH"
    skip "Skipping install."
  else
    echo "  Running: adb install $APK_PATH"
    if adb install "$APK_PATH"; then
      ok "Fully Kiosk Browser installed."
      DONE+=("Installed Fully Kiosk Browser from $APK_PATH")
    else
      err "APK install failed."
    fi
  fi
fi
echo ""

# ── Step 5: Set default launcher ──────────────────────────────────────────────
echo -e "${BOLD}Step 5: Set default launcher${RESET}"
if [[ -z "$RECOMMENDED_LAUNCHER" ]]; then
  skip "No recommended_launcher in profile. Skipping."
else
  echo "  Launcher: ${RECOMMENDED_LAUNCHER}"
  echo "  Will run: adb shell cmd package set-home-activity \"${RECOMMENDED_LAUNCHER}/.FullyKioskActivity\""
  read -rp "  Set as default launcher? (y/n): " DO_LAUNCHER
  if [[ "$DO_LAUNCHER" == "y" ]]; then
    if adb shell cmd package set-home-activity "${RECOMMENDED_LAUNCHER}/.FullyKioskActivity"; then
      ok "Default launcher set to ${RECOMMENDED_LAUNCHER}"
      DONE+=("Set default launcher: ${RECOMMENDED_LAUNCHER}")
    else
      err "Failed to set default launcher."
    fi
  else
    skip "Skipping default launcher configuration."
  fi
fi
echo ""

# ── ADB Notes ─────────────────────────────────────────────────────────────────
if [[ -n "$ADB_NOTES" ]]; then
  echo -e "${BOLD}Device Notes (from profile):${RESET}"
  echo "  $ADB_NOTES"
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD} Revival Summary${RESET}"
echo -e "${BOLD}========================================${RESET}"
if [[ ${#DONE[@]} -eq 0 ]]; then
  echo "  No steps completed."
else
  for item in "${DONE[@]}"; do
    echo -e "  ${GREEN}✓${RESET} $item"
  done
fi
echo -e "${BOLD}========================================${RESET}"
echo ""
