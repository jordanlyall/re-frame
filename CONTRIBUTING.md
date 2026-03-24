# Contributing to re-frame

Thanks for helping grow the library. Contributions of any size are welcome — whether you're adding a device profile, sharing a photo of your frame, or fixing a bug.

## Adding a device profile

1. Copy the JSON template from `devices/README.md` into a new file: `devices/your-device-name.json`
2. Fill in all fields. Use `null` for anything unknown rather than omitting the field.
3. Validate the JSON: `python3 -c "import json; json.load(open('devices/your-device-name.json'))"`
4. Open a pull request. Note in the description how you sourced the revival info (personal testing, forum post, teardown, etc.).

You can also open an [Add device issue](.github/ISSUE_TEMPLATE/add-device.md) if you have partial info and want community help filling in the gaps.

## Adding a gallery theme

Themes live in `gallery/themes/`. Each theme is a single CSS file.

1. Create `gallery/themes/your-theme-name.css`
2. Follow the existing pattern: target `#name`, `#artist`, `#info`, and `#frame` by ID — those are the stable hooks the gallery HTML exposes.
3. Keep it self-contained. No external fonts or assets that require a network request.
4. Open a pull request with a screenshot or brief description of the visual effect.

## Submitting a setup photo

Show us your revived frame in the wild. Photos go in `docs/gallery/`.

1. Add your image to `docs/gallery/` (JPG or PNG, reasonable file size).
2. Add a row to `docs/gallery/README.md` with the frame model, your name or handle, and a one-line description.
3. Open a pull request.

## Code contributions

Keep it simple:

- **Gallery JS**: ES5. No build tools, no bundlers, no transpilation.
- **Scripts** (`scripts/`): Python 3 standard library only. No third-party dependencies.
- **No build step**: Everything should run directly from the repo without an install phase.

If you're unsure whether a change fits the project's direction, open an issue first to discuss it.
