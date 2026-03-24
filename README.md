# re-frame

Your digital art frame isn't dead.

<!-- TODO: Add GIF/photo of revived frame -->

## The Problem

LAGO raised $4.2M, built a beautiful 1920x1920 display, and got acquired by MetaSill. The app was delisted. The website went dark. Thousands of frames became expensive wall decorations overnight.

TokenFrame: same story. Meural is one Netgear decision away from the same fate. Every luxury digital art frame is one acquisition away from becoming e-waste.

re-frame is an open-source toolkit that brings them back to life. It works with any Android-based frame or tablet. No cloud dependency. No subscription. No company to go out of business.

## Quick Start

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
