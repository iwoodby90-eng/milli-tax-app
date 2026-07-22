#!/usr/bin/env python3
"""
Regenerate every iOS + Watch icon slot from the master reference
`/tmp/refs/icon.png`. Uses LANCZOS resampling for crisp downscales.
"""
from PIL import Image
from pathlib import Path

MASTER = Path("/tmp/refs/icon.png")
IOS_DIR = Path("/app/frontend/ios/App/App/Assets.xcassets/AppIcon.appiconset")
WATCH_DIR = Path("/app/frontend/ios/MilliWatch/Assets.xcassets/AppIcon.appiconset")

# filename -> pixel size
IOS = {
    "AppIcon-1024.png": 1024,
    "AppIcon-180@3x.png": 180,          # iphone 60@3x
    "AppIcon-120@2x.png": 120,          # iphone 60@2x
    "AppIcon-87@3x.png": 87,            # iphone 29@3x
    "AppIcon-80@2x-40.png": 80,         # iphone 40@2x
    "AppIcon-120@3x-40.png": 120,       # iphone 40@3x
    "AppIcon-58@2x-29.png": 58,         # iphone 29@2x
    "AppIcon-40@2x-20.png": 40,         # iphone 20@2x
    "AppIcon-60@3x-20.png": 60,         # iphone 20@3x
    "AppIcon-76.png": 76,               # ipad 76@1x
    "AppIcon-152@2x.png": 152,          # ipad 76@2x
    "AppIcon-167@2x.png": 167,          # ipad 83.5@2x
    "AppIcon-29.png": 29,               # ipad 29@1x
    "AppIcon-58@2x-ipad.png": 58,       # ipad 29@2x
    "AppIcon-20.png": 20,               # ipad 20@1x
    "AppIcon-40@2x-ipad.png": 40,       # ipad 20@2x
}

WATCH = {
    "AppIcon-1024.png": 1024,
    "AppIcon-24@2x.png": 48,
    "AppIcon-27.5@2x.png": 55,
    "AppIcon-29@2x.png": 58,
    "AppIcon-29@3x.png": 87,
    "AppIcon-33@2x.png": 66,
    "AppIcon-40@2x.png": 80,
    "AppIcon-44@2x.png": 88,
    "AppIcon-46@2x.png": 92,
    "AppIcon-50@2x.png": 100,
    "AppIcon-55@2x.png": 110,
    "AppIcon-51@2x.png": 102,
    "AppIcon-86@2x.png": 172,
    "AppIcon-98@2x.png": 196,
    "AppIcon-108@2x.png": 216,
}


def render(spec: dict, out_dir: Path, background=(8, 8, 8)):
    """
    Load master, flatten transparency onto solid dark bg (Apple rejects
    icons with an alpha channel), then downscale to every requested size.
    """
    src = Image.open(MASTER).convert("RGBA")
    # composite onto dark bg to eliminate alpha channel (App Store req.)
    bg = Image.new("RGB", src.size, background)
    bg.paste(src, mask=src.split()[3])
    master_rgb = bg

    for filename, size in spec.items():
        img = master_rgb.resize((size, size), Image.LANCZOS)
        out = out_dir / filename
        img.save(out, "PNG", optimize=True)
        print(f"  {out.name:32s}  {size}x{size}")


if __name__ == "__main__":
    print("iOS icons →", IOS_DIR)
    render(IOS, IOS_DIR)
    print("\nWatch icons →", WATCH_DIR)
    render(WATCH, WATCH_DIR)
    print("\nDone.")
