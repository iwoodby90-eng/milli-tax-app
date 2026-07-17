"""Generate the full iOS AppIcon set + a 1024×1024 master from the Milli mark.

Produces all required iOS icon sizes into:
    /app/frontend/ios/App/App/Assets.xcassets/AppIcon.appiconset/

Icons are composited: chrome M mark centered on the Milli noir (#050607)
background with a subtle neon-cyan radial glow to match the app's aesthetic.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

BRAND = Path("/app/frontend/public/brand")
OUT_DIR = Path("/app/frontend/ios/App/App/Assets.xcassets/AppIcon.appiconset")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Icon spec: (filename, size_px, idiom, scale, "size in pt")
ICON_SPEC = [
    ("AppIcon-1024.png",     1024, "ios-marketing", "1x", "1024x1024"),
    ("AppIcon-180@3x.png",   180, "iphone", "3x", "60x60"),
    ("AppIcon-120@2x.png",   120, "iphone", "2x", "60x60"),
    ("AppIcon-87@3x.png",    87,  "iphone", "3x", "29x29"),
    ("AppIcon-80@2x-40.png", 80,  "iphone", "2x", "40x40"),
    ("AppIcon-120@3x-40.png",120, "iphone", "3x", "40x40"),
    ("AppIcon-58@2x-29.png", 58,  "iphone", "2x", "29x29"),
    ("AppIcon-40@2x-20.png", 40,  "iphone", "2x", "20x20"),
    ("AppIcon-60@3x-20.png", 60,  "iphone", "3x", "20x20"),
    ("AppIcon-76.png",       76,  "ipad",   "1x", "76x76"),
    ("AppIcon-152@2x.png",   152, "ipad",   "2x", "76x76"),
    ("AppIcon-167@2x.png",   167, "ipad",   "2x", "83.5x83.5"),
    ("AppIcon-29.png",       29,  "ipad",   "1x", "29x29"),
    ("AppIcon-58@2x-ipad.png", 58, "ipad",  "2x", "29x29"),
    ("AppIcon-20.png",       20,  "ipad",   "1x", "20x20"),
    ("AppIcon-40@2x-ipad.png", 40, "ipad",  "2x", "20x20"),
]

def build_master(size: int) -> Image.Image:
    """Compose the Milli app icon at ``size`` × ``size``.

    Strategy: sample the source mark's edge color so the canvas fill
    matches seamlessly, then paste the mark at 78% width centered.
    The result reads as one continuous icon at 1024px and clearly at 20px.
    """
    mark = Image.open(BRAND / "milli-mark.png").convert("RGBA")

    # Sample corner color from the mark and use that as the canvas fill.
    corner = mark.getpixel((2, 2))              # top-left corner pixel
    fill = (corner[0], corner[1], corner[2]) if len(corner) >= 3 else (5, 6, 7)

    canvas = Image.new("RGB", (size, size), fill)

    # Add a soft carbon gradient so the icon has depth, not a flat plate.
    grad = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for i in range(0, size, 4):                 # subtle radial darkening
        alpha = int(60 * (i / size))
        gd.ellipse((-i, -i, size + i, size + i),
                    outline=(0, 0, 0, alpha), width=2)
    canvas.paste(grad, (0, 0), grad)

    # Paste the chrome M mark centered, scaled to 78% of icon width.
    target_w = int(size * 0.78)
    ratio = target_w / mark.width
    target_h = int(mark.height * ratio)
    mark = mark.resize((target_w, target_h), Image.LANCZOS)
    x = (size - target_w) // 2
    y = (size - target_h) // 2
    canvas.paste(mark, (x, y), mark)

    # Neon cyan floor glow under the M (matches the app's runway motif).
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gld = ImageDraw.Draw(glow)
    r = int(size * 0.25)
    cx = size // 2
    cy = int(size * 0.72)
    for i, alpha in enumerate([22, 34, 50]):
        rr = r + i * int(size * 0.04)
        gld.ellipse((cx - rr, cy - rr, cx + rr, cy + rr),
                     fill=(0, 229, 255, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.05))
    canvas.paste(glow, (0, 0), glow)

    # Re-paste the mark on top of the glow so silver stays on top.
    canvas.paste(mark, (x, y), mark)
    return canvas


master = build_master(1024)
for filename, px, *_ in ICON_SPEC:
    img = master.resize((px, px), Image.LANCZOS) if px < 1024 else master
    img.save(OUT_DIR / filename, "PNG", optimize=True)
    print(f"  wrote {filename} ({px}x{px})")

# Write Contents.json manifest so Xcode picks the icons up.
import json
images = []
for filename, px, idiom, scale, sz in ICON_SPEC:
    entry = {"filename": filename, "idiom": idiom, "scale": scale, "size": sz}
    images.append(entry)
manifest = {"images": images, "info": {"author": "milli", "version": 1}}
(OUT_DIR / "Contents.json").write_text(json.dumps(manifest, indent=2))
print("wrote Contents.json")

# Delete the stale AppIcon-512@2x.png that Capacitor scaffolded.
stale = OUT_DIR / "AppIcon-512@2x.png"
if stale.exists():
    stale.unlink()
    print("removed stale AppIcon-512@2x.png")
