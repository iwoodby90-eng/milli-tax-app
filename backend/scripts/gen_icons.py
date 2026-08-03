"""
Milli — App Icon Set Generator.

Produces every icon size Apple / Google needs, from a single 1024×1024
source. Run:

    cd /app/backend
    python -m scripts.gen_icons

Output goes to /app/frontend/public/appstore-icons/{ios,ipad,mac,watch,android,wear}/
"""
from pathlib import Path
from PIL import Image, ImageFilter

SRC = Path("/app/frontend/public/brand/milli-icon-1024.png")
OUT = Path("/app/frontend/public/appstore-icons")

# ------------------------- source normalization -------------------------
def _load_source() -> Image.Image:
    img = Image.open(SRC).convert("RGBA")
    # Ensure square canvas
    w, h = img.size
    if w != h:
        side = max(w, h)
        canvas = Image.new("RGBA", (side, side), (5, 7, 10, 255))
        canvas.paste(img, ((side - w) // 2, (side - h) // 2))
        img = canvas
    return img.resize((1024, 1024), Image.LANCZOS)

def _round_corners(img: Image.Image, radius_ratio: float = 0.225) -> Image.Image:
    """Apple's "squircle" ratio ~0.225; approximate with a rounded rect."""
    from PIL import ImageDraw
    r = int(img.width * radius_ratio)
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, img.width, img.height), radius=r, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, mask=mask)
    return out

def _circle_mask(img: Image.Image) -> Image.Image:
    """Apple Watch icons are circular."""
    from PIL import ImageDraw
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((0, 0, img.width, img.height), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, mask=mask)
    return out

# ------------------------- generators -------------------------
def gen_ios_iphone(src: Image.Image):
    """Apple's AppIcon set for iPhone. Names match Xcode Assets.xcassets."""
    d = OUT / "ios_iphone"; d.mkdir(parents=True, exist_ok=True)
    # (filename, size)  — non-alpha PNGs. Apple auto-masks.
    icons = [
        ("Icon-App-1024x1024@1x.png", 1024),
        ("Icon-App-180x180.png", 180),
        ("Icon-App-167x167.png", 167),
        ("Icon-App-152x152.png", 152),
        ("Icon-App-120x120.png", 120),
        ("Icon-App-87x87.png", 87),
        ("Icon-App-80x80.png", 80),
        ("Icon-App-76x76.png", 76),
        ("Icon-App-60x60.png", 60),
        ("Icon-App-58x58.png", 58),
        ("Icon-App-40x40.png", 40),
        ("Icon-App-29x29.png", 29),
        ("Icon-App-20x20.png", 20),
    ]
    # Apple wants NO alpha — flatten onto black
    base = Image.new("RGB", src.size, (5, 7, 10))
    base.paste(src, mask=src.getchannel("A"))
    for name, size in icons:
        base.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    print(f"  ✓ {len(icons)} iOS iPhone icons → {d}")

def gen_ipad(src: Image.Image):
    d = OUT / "ios_ipad"; d.mkdir(parents=True, exist_ok=True)
    icons = [
        ("Icon-App-iPad-Pro-167x167@2x.png", 167),
        ("Icon-App-iPad-152x152@2x.png", 152),
        ("Icon-App-iPad-76x76.png", 76),
        ("Icon-App-iPad-58x58@2x.png", 58),
        ("Icon-App-iPad-29x29.png", 29),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    base = Image.new("RGB", src.size, (5, 7, 10))
    base.paste(src, mask=src.getchannel("A"))
    for name, size in icons:
        base.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    print(f"  ✓ {len(icons)} iPad icons → {d}")

def gen_mac(src: Image.Image):
    d = OUT / "mac"; d.mkdir(parents=True, exist_ok=True)
    # Mac icons ARE rounded and DO carry alpha
    rounded = _round_corners(src)
    icons = [
        ("icon_512x512@2x.png", 1024),
        ("icon_512x512.png", 512),
        ("icon_256x256@2x.png", 512),
        ("icon_256x256.png", 256),
        ("icon_128x128@2x.png", 256),
        ("icon_128x128.png", 128),
        ("icon_32x32@2x.png", 64),
        ("icon_32x32.png", 32),
        ("icon_16x16@2x.png", 32),
        ("icon_16x16.png", 16),
    ]
    for name, size in icons:
        rounded.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    print(f"  ✓ {len(icons)} macOS icons → {d}")

def gen_watch(src: Image.Image):
    d = OUT / "watch"; d.mkdir(parents=True, exist_ok=True)
    circular = _circle_mask(src)
    base = Image.new("RGB", src.size, (5, 7, 10))
    base.paste(src, mask=src.getchannel("A"))  # square flat for AppIcon
    icons_square = [
        ("Notification-Center-24@2x.png", 48),
        ("Notification-Center-27.5@2x.png", 55),
        ("Home-Screen-44@2x.png", 88),
        ("Home-Screen-50@2x.png", 100),
        ("Long-Look-86@2x.png", 172),
        ("Long-Look-98@2x.png", 196),
        ("AppStore-1024.png", 1024),
    ]
    for name, size in icons_square:
        base.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    # complications
    for name, size in [("Complication-32@2x.png", 64), ("Complication-32@3x.png", 96)]:
        circular.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    print(f"  ✓ {len(icons_square) + 2} Apple Watch icons → {d}")

def gen_android(src: Image.Image):
    d = OUT / "android"; d.mkdir(parents=True, exist_ok=True)
    rounded = _round_corners(src, radius_ratio=0.20)
    circular = _circle_mask(src)
    icons = [
        ("mipmap-mdpi/ic_launcher.png", 48),
        ("mipmap-hdpi/ic_launcher.png", 72),
        ("mipmap-xhdpi/ic_launcher.png", 96),
        ("mipmap-xxhdpi/ic_launcher.png", 144),
        ("mipmap-xxxhdpi/ic_launcher.png", 192),
        ("mipmap-mdpi/ic_launcher_round.png", 48),
        ("mipmap-hdpi/ic_launcher_round.png", 72),
        ("mipmap-xhdpi/ic_launcher_round.png", 96),
        ("mipmap-xxhdpi/ic_launcher_round.png", 144),
        ("mipmap-xxxhdpi/ic_launcher_round.png", 192),
        ("play_store_512.png", 512),
    ]
    for name, size in icons:
        (d / name).parent.mkdir(parents=True, exist_ok=True)
        img = circular if "round" in name else rounded
        img.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    print(f"  ✓ {len(icons)} Android icons → {d}")

def gen_wear_os(src: Image.Image):
    d = OUT / "wear_os"; d.mkdir(parents=True, exist_ok=True)
    circular = _circle_mask(src)
    icons = [
        ("mipmap-mdpi/ic_launcher.png", 48),
        ("mipmap-hdpi/ic_launcher.png", 72),
        ("mipmap-xhdpi/ic_launcher.png", 96),
        ("mipmap-xxhdpi/ic_launcher.png", 144),
        ("mipmap-xxxhdpi/ic_launcher.png", 192),
        ("play_store_512.png", 512),
    ]
    for name, size in icons:
        (d / name).parent.mkdir(parents=True, exist_ok=True)
        circular.resize((size, size), Image.LANCZOS).save(d / name, "PNG", optimize=True)
    print(f"  ✓ {len(icons)} Wear OS icons → {d}")


# ------------------------- entrypoint -------------------------
if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    src = _load_source()
    print(f"Source: {SRC.name} ({src.size[0]}×{src.size[1]})")
    print(f"Output: {OUT}")
    gen_ios_iphone(src)
    gen_ipad(src)
    gen_mac(src)
    gen_watch(src)
    gen_android(src)
    gen_wear_os(src)
    print("\nDone. Zip the folder and upload the pieces you need per platform.")
