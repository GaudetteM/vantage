#!/usr/bin/env python3
"""
Generates assets/images/icon.png and assets/images/icon_foreground.png
for the Vantage app icon, matching the in-game HUD/title logo exactly.

Requirements:
    pip3 install Pillow

Run from the project root:
    python3 generate_icons.py
    dart run flutter_launcher_icons
"""
from pathlib import Path
from PIL import Image, ImageDraw

SIZE   = 1024
CX, CY = SIZE // 2, SIZE // 2

# Colours matching vantage_theme.dart
BG          = (13,  13,  26)    # #0D0D1A
CLR_NORTH   = (129, 199, 132)   # #81C784 green
CLR_EAST    = (255, 200, 87)    # #FFC857 amber
CLR_SOUTH   = (229, 115, 115)   # #E57373 red
CLR_WEST    = (124, 77,  255)   # #7C4DFF purple
CLR_CENTRE  = (0,   229, 255)   # #00E5FF cyan

OUTER_DOT   = 88    # radius of N/E/S/W dots
CENTRE_DOT  = 54    # radius of centre dot
REACH       = 308   # distance from centre to outer dot


def _glow(draw, x, y, radius, rgb, layers=7):
    """Paint a soft radial glow beneath a dot."""
    for i in range(layers, 0, -1):
        alpha = int(55 * (i / layers))
        r = radius + i * 14
        draw.ellipse([x - r, y - r, x + r, y + r], fill=rgb + (alpha,))


def _dot(draw, x, y, radius, rgb):
    _glow(draw, x, y, radius, rgb)
    draw.ellipse([x - radius, y - radius, x + radius, y + radius],
                 fill=rgb + (255,))


def build(transparent_bg: bool) -> Image.Image:
    bg_pixel = (0, 0, 0, 0) if transparent_bg else BG + (255,)
    img  = Image.new("RGBA", (SIZE, SIZE), bg_pixel)
    draw = ImageDraw.Draw(img)

    for (x, y, clr) in [
        (CX,         CY - REACH, CLR_NORTH),
        (CX + REACH, CY,         CLR_EAST),
        (CX,         CY + REACH, CLR_SOUTH),
        (CX - REACH, CY,         CLR_WEST),
    ]:
        _dot(draw, x, y, OUTER_DOT, clr)

    _dot(draw, CX, CY, CENTRE_DOT, CLR_CENTRE)
    return img


out = Path("assets/images")
out.mkdir(parents=True, exist_ok=True)

build(transparent_bg=False).save(out / "icon.png")
print("✓  assets/images/icon.png")

build(transparent_bg=True).save(out / "icon_foreground.png")
print("✓  assets/images/icon_foreground.png")

print("\nAll done. Now run:")
print("  dart run flutter_launcher_icons")
