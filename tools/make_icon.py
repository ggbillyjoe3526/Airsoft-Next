"""Builds installer/icon.ico (the setup wizard, Start Menu and desktop shortcut icon) from icon.svg.

Run:  python3 tools/make_icon.py   (from the project root). Requires Pillow.
icon.svg is drawn from plain <rect> and <circle> elements with #rrggbb fills (fill-opacity allowed), so this script
paints them directly at 4x and scales down, giving smooth edges at every Windows icon size. Re-run it whenever
icon.svg changes. Adapted from the owner's katanashotgun project.
"""
import os
import re
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "icon.svg")
OUT = os.path.join(ROOT, "installer", "icon.ico")
SIZES = [16, 24, 32, 48, 64, 128, 256]
SUPER = 4


def colour(el):
    fill = el.get("fill", "#000000")
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", fill):
        raise SystemExit("unsupported fill %r (use #rrggbb)" % fill)
    alpha = round(float(el.get("fill-opacity", "1")) * 255)
    return tuple(int(fill[i:i + 2], 16) for i in (1, 3, 5)) + (alpha,)


def main() -> None:
    root = ET.parse(SRC).getroot()
    side = int(float(root.get("width"))) * SUPER
    img = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    for el in root.iter():
        tag = el.tag.split("}")[-1]
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        if tag == "rect":
            x, y = float(el.get("x", 0)) * SUPER, float(el.get("y", 0)) * SUPER
            w, h = float(el.get("width")) * SUPER, float(el.get("height")) * SUPER
            draw.rounded_rectangle([x, y, x + w - 1, y + h - 1], radius=float(el.get("rx", 0)) * SUPER, fill=colour(el))
        elif tag == "circle":
            cx, cy, r = (float(el.get(k)) * SUPER for k in ("cx", "cy", "r"))
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=colour(el))
        else:
            continue
        img = Image.alpha_composite(img, layer)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.resize((256, 256), Image.LANCZOS).save(OUT, sizes=[(s, s) for s in SIZES])
    print("wrote", OUT)


if __name__ == "__main__":
    main()
