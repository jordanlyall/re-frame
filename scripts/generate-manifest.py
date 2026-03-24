#!/usr/bin/env python3
"""
generate-manifest.py

Scans gallery/assets/ and generates gallery/manifest.json.
Run from anywhere; script finds the repo root relative to its own location.
"""

import os
import json
import sys

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp"}
IFRAME_EXTENSIONS = {".html"}

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
ASSETS_DIR = os.path.join(REPO_ROOT, "gallery", "assets")
MANIFEST_PATH = os.path.join(REPO_ROOT, "gallery", "manifest.json")


def to_name(filename):
    base = os.path.splitext(filename)[0]
    return base.replace("-", " ").replace("_", " ").title()


def get_type(ext):
    if ext in IMAGE_EXTENSIONS:
        return "image"
    if ext in IFRAME_EXTENSIONS:
        return "iframe"
    return None


def main():
    if not os.path.isdir(ASSETS_DIR):
        print(f"Error: assets directory not found: {ASSETS_DIR}", file=sys.stderr)
        sys.exit(1)

    entries = []
    for filename in sorted(os.listdir(ASSETS_DIR)):
        ext = os.path.splitext(filename)[1].lower()
        entry_type = get_type(ext)
        if entry_type is None:
            continue
        entries.append({
            "url": f"/assets/{filename}",
            "name": to_name(filename),
            "artist": "Unknown",
            "type": entry_type,
        })

    with open(MANIFEST_PATH, "w") as f:
        json.dump(entries, f, indent=2)
        f.write("\n")

    print(f"{len(entries)} entries written to {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
