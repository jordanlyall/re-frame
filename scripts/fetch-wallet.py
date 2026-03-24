#!/usr/bin/env python3
"""Wallet-to-gallery pipeline via Alchemy NFT API."""

import json
import os
import sys
import urllib.request
import urllib.error
from urllib.parse import urlparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)

CONFIG_PATH = os.path.join(REPO_ROOT, "config.json")
GALLERY_DIR = os.path.join(REPO_ROOT, "gallery")
ASSETS_DIR = os.path.join(GALLERY_DIR, "assets")
MANIFEST_PATH = os.path.join(GALLERY_DIR, "manifest.json")

AB_CONTRACTS = {
    "0xa7d8d9ef8d8ce8992df33d8b8cf4aebabd5bd270",  # Art Blocks core
    "0x99a9b7c1116f9ceeb1652de04d5969cce509b069",  # Art Blocks flex
}


def load_config():
    if not os.path.exists(CONFIG_PATH):
        print(f"Error: config.json not found at {CONFIG_PATH}", file=sys.stderr)
        sys.exit(1)

    with open(CONFIG_PATH) as f:
        config = json.load(f)

    address = config.get("wallet", {}).get("address", "").strip()
    api_key = config.get("wallet", {}).get("api_key", "").strip()

    if not address:
        print("Error: wallet.address is empty in config.json", file=sys.stderr)
        sys.exit(1)
    if not api_key:
        print("Error: wallet.api_key is empty in config.json", file=sys.stderr)
        sys.exit(1)

    return address, api_key


def fetch_nfts(address, api_key):
    url = (
        f"https://eth-mainnet.g.alchemy.com/nft/v3/{api_key}/getNFTsForOwner"
        f"?owner={address}&withMetadata=true"
    )

    req = urllib.request.Request(url, headers={"Accept": "application/json"})

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 429:
            print("Rate limited by Alchemy API. Wait a moment and retry.", file=sys.stderr)
        else:
            print(f"HTTP error {e.code} from Alchemy API: {e.reason}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Network error contacting Alchemy API: {e.reason}", file=sys.stderr)
        sys.exit(1)

    owned = data.get("ownedNfts", [])
    if not owned:
        print(f"No NFTs found for address {address}", file=sys.stderr)
        sys.exit(1)

    return owned


def download_image(image_url, contract, token_id):
    os.makedirs(ASSETS_DIR, exist_ok=True)

    parsed = urlparse(image_url)
    path = parsed.path
    ext = os.path.splitext(path)[1]
    if not ext or len(ext) > 5:
        ext = ".png"

    filename = f"{contract.lower()}-{token_id}{ext}"
    dest = os.path.join(ASSETS_DIR, filename)

    if os.path.exists(dest):
        return f"/assets/{filename}"

    try:
        req = urllib.request.Request(image_url, headers={"User-Agent": "re-frame/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            with open(dest, "wb") as f:
                f.write(resp.read())
    except Exception as e:
        print(f"Warning: could not download image for {contract}-{token_id}: {e}", file=sys.stderr)
        return None

    return f"/assets/{filename}"


def build_entry(nft):
    contract = nft.get("contract", {}).get("address", "").lower()
    token_id = nft.get("tokenId", "")

    raw_name = nft.get("name") or nft.get("title") or ""
    contract_name = (
        nft.get("contract", {}).get("name")
        or nft.get("contract", {}).get("openSeaMetadata", {}).get("collectionName")
        or ""
    )

    if contract in AB_CONTRACTS:
        url = f"https://generator.artblocks.io/{contract}/{token_id}"
        return {
            "url": url,
            "name": raw_name,
            "artist": contract_name,
            "type": "iframe",
        }
    else:
        image_url = (
            nft.get("image", {}).get("cachedUrl")
            or nft.get("image", {}).get("originalUrl")
            or nft.get("metadata", {}).get("image")
            or ""
        )

        local_url = None
        if image_url:
            local_url = download_image(image_url, contract, token_id)

        if not local_url:
            return None

        return {
            "url": local_url,
            "name": raw_name,
            "artist": contract_name,
            "type": "image",
        }


def main():
    address, api_key = load_config()
    owned = fetch_nfts(address, api_key)

    manifest = []
    live_count = 0
    static_count = 0

    for nft in owned:
        entry = build_entry(nft)
        if entry is None:
            continue
        manifest.append(entry)
        if entry["type"] == "iframe":
            live_count += 1
        else:
            static_count += 1

    if not manifest:
        print("Error: processed NFTs but produced no manifest entries — check image availability.", file=sys.stderr)
        sys.exit(1)

    os.makedirs(GALLERY_DIR, exist_ok=True)
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=2)

    total = live_count + static_count
    print(f"Fetched {total} NFTs ({live_count} live, {static_count} static)")


if __name__ == "__main__":
    main()
