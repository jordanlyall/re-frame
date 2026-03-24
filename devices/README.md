# Device Profiles

A device profile is a JSON file that describes a specific digital frame model — its hardware capabilities, system software, and revival instructions. The `revive.sh` script reads these profiles to know which vendor packages to uninstall, which launcher to recommend, and how to handle device-specific quirks. Community members contribute profiles for their own frames via pull request, building a shared knowledge base for reviving abandoned hardware.

## JSON Schema

| Field | Type | Description |
|---|---|---|
| `name` | string | Human-readable device name |
| `manufacturer` | string | Manufacturer or brand name |
| `status` | string | Device lifecycle status: `"active"`, `"defunct"`, or `"unknown"` |
| `display.size_inches` | number | Diagonal screen size in inches |
| `display.resolution` | string | Native resolution as `"WxH"` |
| `display.aspect` | string | Aspect ratio as `"W:H"` |
| `system.soc` | string | System-on-chip model |
| `system.android_version` | number | Android OS version |
| `system.webview_version` | number | Android WebView version (critical for generative art compatibility) |
| `capabilities.canvas_2d` | boolean | Whether Canvas 2D API works reliably |
| `capabilities.webgl` | boolean | Whether WebGL is supported |
| `capabilities.video_playback` | boolean | Whether HTML5 video plays |
| `capabilities.audio` | boolean | Whether audio output works |
| `revival.dead_packages` | array | Package names to uninstall to free the device |
| `revival.adb_notes` | string | ADB connectivity and developer options notes |
| `revival.recommended_launcher` | string | Package name of the recommended replacement launcher |

## Adding a Profile for Your Frame

1. Copy the template below into a new file: `devices/your-device-name.json`
2. Fill in all fields. Use `null` for unknown values rather than omitting fields.
3. Test that the JSON is valid: `python3 -c "import json; json.load(open('devices/your-device-name.json'))"`
4. Open a pull request. Include a brief note in the PR description about how you sourced the revival info.

## Template

```json
{
  "name": "Device Name",
  "manufacturer": "Manufacturer Name",
  "status": "defunct",
  "display": {
    "size_inches": 0,
    "resolution": "0x0",
    "aspect": "0:0"
  },
  "system": {
    "soc": "Chip Model",
    "android_version": 0,
    "webview_version": 0
  },
  "capabilities": {
    "canvas_2d": null,
    "webgl": null,
    "video_playback": null,
    "audio": null
  },
  "revival": {
    "dead_packages": [],
    "adb_notes": "Notes on ADB access and developer options.",
    "recommended_launcher": "com.launcher.package"
  }
}
```
