# re-frame

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Devices](https://img.shields.io/badge/devices-1-blue.svg)](devices/)
[![No Build Step](https://img.shields.io/badge/build_step-none-lightgrey.svg)]()

Your digital art frame isn't dead.

<!-- TODO: Add GIF/photo of revived frame -->

## The Problem

LAGO raised $4.2M, built a beautiful 1920x1920 display, and got acquired by MetaSill. The app was delisted. The website went dark. Thousands of frames became expensive wall decorations overnight.

TokenFrame: same story. Meural is one Netgear decision away from the same fate. Every luxury digital art frame is one acquisition away from becoming e-waste.

re-frame is an open-source toolkit that brings them back to life. It works with any Android-based frame or tablet. No cloud dependency. No subscription. No company to go out of business.

## How It Works

Most "smart" digital art frames are just Android tablets in a nice enclosure. When the company dies and the app gets delisted, the frame boots to a dead launcher. But Android is still running underneath. re-frame uses ADB (Android Debug Bridge) to bypass the dead software, install a kiosk browser, and point it at a local gallery page that displays your art.

The whole process takes about 15 minutes. You can do it manually or let an AI coding tool (like Claude Code) walk you through it using this repo as context.

## Before You Start

You'll need a few things set up before running the revival scripts.

### On your computer

- **ADB installed.** This is how your computer talks to the frame.
  - macOS: `brew install android-platform-tools`
  - Linux: `sudo apt install adb`
  - Windows: [Download from Google](https://developer.android.com/tools/releases/platform-tools)
- **Python 3.** Already installed on most systems. Check with `python3 --version`.
- **scrcpy (optional).** Mirrors the frame's screen on your computer during setup. Very helpful for navigating Android UI on a wall-mounted display. Install: `brew install scrcpy` (macOS) or see [scrcpy repo](https://github.com/Genymobile/scrcpy).

### On your frame

These steps happen on the frame itself (use a USB mouse or scrcpy to navigate):

1. **Escape the dead launcher.** Most bricked frames still respond to touch. Look for a Settings gear, swipe from edges, or long-press to access Android's home screen. Every frame is different. Check your device profile in `devices/` for specific instructions.

2. **Connect to WiFi.** The frame and your computer must be on the same network. Go to Settings > WiFi and connect.

3. **Enable Developer Options.** Go to Settings > About (or About Device/Tablet). Tap "Build Number" 7 times. You'll see a toast message: "You are now a developer."

4. **Enable USB Debugging and Wireless Debugging.** Go to Settings > Developer Options. Turn on "USB Debugging." If available, also turn on "Wireless Debugging" (Android 11+). This lets ADB connect over WiFi without a USB cable.

5. **Assign a static IP (recommended).** Log into your router and assign a DHCP reservation for the frame's MAC address. This way the frame always gets the same IP, so your scripts and bookmarks don't break after a reboot. Find the MAC under Settings > About > WiFi MAC Address.

### Kiosk browser

re-frame uses [Fully Kiosk Browser](https://www.fully-kiosk.com/) to display the gallery in a locked-down, chromeless fullscreen view. It costs about 8 EUR (one-time) for the Plus license. The free version works but shows a watermark.

The `revive.sh` script can install the APK for you via ADB. Download the APK from [fully-kiosk.com](https://www.fully-kiosk.com/en/#download) and have the file path ready.

Alternatives: [WallPanel](https://github.com/TheTimeWalker/wallpanel-android) (free, open source) works too. Any browser that supports kiosk mode and auto-start will do the job.

## Quick Start

Once the prerequisites above are done:

1. Clone the repo:
   ```bash
   git clone https://github.com/jordanlyall/re-frame.git
   cd re-frame
   ```

2. Copy the config:
   ```bash
   cp config.example.json config.json
   ```

3. Revive your frame (or skip this step if your frame is already network-accessible):
   ```bash
   ./scripts/revive.sh lago-genesis
   ```

4. Add art. Two options:

   **Local mode:** Drop images into `gallery/assets/`, then run:
   ```bash
   python3 scripts/generate-manifest.py
   ```

   **Wallet mode:** Edit `config.json` with your wallet address and Alchemy API key, then run:
   ```bash
   python3 scripts/fetch-wallet.py
   ```

5. Serve the gallery and point your frame's browser at it:
   ```bash
   cd gallery && python3 -m http.server 8080
   ```
   Then open `http://<your-ip>:8080` on the frame.

## Supported Devices

| Device | Display | Status | Profile |
|--------|---------|--------|---------|
| LAGO Genesis | 1920x1920 | Defunct | [lago-genesis.json](devices/lago-genesis.json) |

Your frame not listed? [Add it](devices/README.md) or [open an issue](.github/ISSUE_TEMPLATE/add-device.md).

## Gallery

The gallery runs entirely in the browser. No server required beyond a basic file server.

**Local mode** serves images from `gallery/assets/`. Run `generate-manifest.py` any time you add or remove files and the gallery picks up the changes on next load.

**Wallet mode** fetches NFT metadata from your wallet using the Alchemy API. Tokens are cached locally so the gallery works offline after the first fetch.

Three themes are included:

- **dark**: High contrast, minimal UI. Black background, white text. Built for dimly lit rooms.
- **museum**: Off-white background with generous margins. Treats every piece like it belongs on a wall.
- **minimal**: No labels, no chrome. Just the art, full screen.

To change themes, set `"theme"` in `config.json`.

## Camera-Aware Brightness

The frame dims automatically when your webcam turns on and returns to full brightness when it turns off. Useful if your frame is visible on video calls and you'd rather not have it compete with your face.

To run it:
```bash
python3 scripts/camera-watch.py
```

macOS only for now. The script uses the system camera indicator to detect active sessions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide. The easiest contribution is adding a device profile: copy the JSON template from `devices/README.md`, fill in what you know, and open a pull request. Partial info is better than no info.

## Community Gallery

Photos of revived frames in the wild live in [docs/gallery/](docs/gallery/). Show us your frame.

## License

MIT. See [LICENSE](LICENSE).
