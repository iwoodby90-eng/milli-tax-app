"""
Upload Milli marketing videos to gofile.io for permanent public URLs.

Gofile.io accepts anonymous uploads without an API key. Each file gets a
shareable downloadPage URL (HTML page where any visitor can stream/download
the MP4) and a direct CDN URL constructed from the assigned server.

Outputs a JSON map at /app/marketing_videos/public_urls.json:
    {
      "01_cinematic_luxury": {
        "downloadPage": "https://gofile.io/d/XXXXXX",
        "directUrl":    "https://store-XX.gofile.io/download/.../file.mp4",
        "fileId":       "uuid",
        "size":         12345
      },
      ...
    }
"""
import json
import sys
import time
from pathlib import Path

import requests

VIDEOS_DIR = Path("/app/marketing_videos")
OUT_PATH = VIDEOS_DIR / "public_urls.json"

FILES = [
    ("01_cinematic_luxury",   "Cinematic Luxury — Skyline",       "9:16"),
    ("02_driver_pov_hud",     "Driver POV — Night HUD",           "16:9"),
    ("03_lifestyle_gigworker", "Lifestyle — Gig Worker Smile",     "9:16"),
    ("04_product_kinetic_type", "Product — Kinetic Typography",    "16:9"),
    ("05_hero_montage",       "Hero Brand Montage",                "9:16"),
]


def get_server():
    """Pick a random available upload server."""
    r = requests.get("https://api.gofile.io/servers", timeout=30)
    r.raise_for_status()
    servers = r.json()["data"]["servers"]
    if not servers:
        raise RuntimeError("No gofile servers available")
    return servers[0]["name"]


def upload(path: Path, server: str) -> dict:
    url = f"https://{server}.gofile.io/contents/uploadfile"
    with path.open("rb") as f:
        files = {"file": (path.name, f, "video/mp4")}
        r = requests.post(url, files=files, timeout=300)
    r.raise_for_status()
    data = r.json()
    if data.get("status") != "ok":
        raise RuntimeError(f"Upload failed: {data}")
    return data["data"]


def main():
    existing = {}
    if OUT_PATH.exists():
        try:
            existing = json.loads(OUT_PATH.read_text())
        except Exception:
            existing = {}

    server = get_server()
    print(f"Using server: {server}", flush=True)
    results = dict(existing)

    for cid, title, aspect in FILES:
        if cid in results and isinstance(results[cid], dict) and results[cid].get("downloadPage"):
            print(f"[skip] {cid} already uploaded -> {results[cid]['downloadPage']}", flush=True)
            continue
        path = VIDEOS_DIR / f"{cid}.mp4"
        if not path.exists():
            print(f"[missing] {path}", flush=True)
            continue

        size_mb = path.stat().st_size / 1024 / 1024
        print(f"[upload] {cid} ({size_mb:.2f} MB)...", flush=True)
        try:
            data = upload(path, server)
            results[cid] = {
                "title": title,
                "aspect": aspect,
                "downloadPage": data.get("downloadPage"),
                "fileId": data.get("id"),
                "parentFolderCode": data.get("parentFolderCode"),
                "size": data.get("size"),
                "md5": data.get("md5"),
                "mimetype": data.get("mimetype"),
                "guestToken": data.get("guestToken"),
            }
            print(f"[done]   {cid} -> {results[cid]['downloadPage']}", flush=True)
        except Exception as e:
            print(f"[error]  {cid}: {e}", flush=True)
            results[cid] = {"error": str(e)}
        OUT_PATH.write_text(json.dumps(results, indent=2))
        time.sleep(0.5)

    print("\n=== FINAL PUBLIC URLS ===")
    for cid, info in results.items():
        page = info.get("downloadPage") if isinstance(info, dict) else None
        print(f"{cid}: {page or info}")
    print(f"\nSaved to {OUT_PATH}")


if __name__ == "__main__":
    main()
