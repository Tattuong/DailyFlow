#!/usr/bin/env python3
"""Two violet waves for the DailyFlow launcher."""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
LILAC = (246, 243, 251, 255)
VIOLET = (109, 74, 255, 255)


def _wave(draw: ImageDraw.ImageDraw, y: float, phase: float) -> None:
    left, right = 292, 732
    amplitude = 46
    thickness = 52
    steps = 80
    centers = []
    for i in range(steps + 1):
        t = i / steps
        x = left + t * (right - left)
        sway = math.sin(t * math.pi * 2 + phase) * amplitude
        centers.append((x, y + sway))
    top = []
    bottom = []
    for i, (x, cy) in enumerate(centers):
        if i == 0:
            dx, dy = centers[1][0] - x, centers[1][1] - cy
        elif i == steps:
            dx, dy = x - centers[i - 1][0], cy - centers[i - 1][1]
        else:
            dx = centers[i + 1][0] - centers[i - 1][0]
            dy = centers[i + 1][1] - centers[i - 1][1]
        length = math.hypot(dx, dy) or 1
        ox, oy = -dy / length * thickness / 2, dx / length * thickness / 2
        top.append((x + ox, cy + oy))
        bottom.append((x - ox, cy - oy))
    draw.polygon(top + bottom[::-1], fill=VIOLET)
    radius = thickness / 2
    for x, cy in (centers[0], centers[-1]):
        draw.ellipse((x - radius, cy - radius, x + radius, cy + radius), fill=VIOLET)


def _mark(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    _wave(draw, 430, 0.2)
    _wave(draw, 590, 0.7)


def main() -> None:
    assets = ROOT / "assets"
    assets.mkdir(exist_ok=True)

    logo = Image.new("RGBA", (SIZE, SIZE), LILAC)
    _mark(logo)
    logo.convert("RGB").save(assets / "logo.png", optimize=True)

    splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    _mark(splash)
    splash_path = ROOT / "android/app/src/main/res/drawable-nodpi/splash_icon.png"
    splash_path.parent.mkdir(parents=True, exist_ok=True)
    splash.save(splash_path, optimize=True)
    print(f"wrote {assets / 'logo.png'}")


if __name__ == "__main__":
    main()
