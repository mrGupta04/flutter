"""Generate premium 3D-style anatomical organ illustrations (PIL)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "assets" / "images" / "organs"
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 512


def canvas() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def radial_blob(
    img: Image.Image,
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    inner: tuple[int, int, int],
    outer: tuple[int, int, int],
    alpha: int = 255,
) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    steps = 28
    for i in range(steps, 0, -1):
        t = i / steps
        color = (
            int(inner[0] * t + outer[0] * (1 - t)),
            int(inner[1] * t + outer[1] * (1 - t)),
            int(inner[2] * t + outer[2] * (1 - t)),
            int(alpha * (0.35 + 0.65 * t)),
        )
        draw.ellipse(
            (cx - rx * t, cy - ry * t, cx + rx * t, cy + ry * t),
            fill=color,
        )
    img.alpha_composite(layer)


def soft_shadow(img: Image.Image, offset: tuple[int, int] = (0, 18)) -> Image.Image:
    alpha = img.split()[-1]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.putalpha(alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    result = Image.new("RGBA", img.size, (0, 0, 0, 0))
    result.alpha_composite(shadow, offset)
    result.alpha_composite(img)
    return result


def draw_liver() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    body = [
        (170, 210), (210, 150), (290, 130), (360, 155), (390, 210),
        (380, 280), (330, 330), (250, 350), (180, 320), (150, 260),
    ]
    draw.polygon(body, fill=(168, 72, 58, 255))
    radial_blob(img, 270, 230, 120, 90, (210, 95, 75), (120, 45, 35))
    radial_blob(img, 220, 200, 55, 40, (235, 130, 105), (150, 60, 45), 180)
    draw.ellipse((300, 175, 340, 215), fill=(120, 40, 35, 220))
    return soft_shadow(img)


def draw_lungs() -> Image.Image:
    img = canvas()
    for cx, flip in ((205, 1), (307, -1)):
        layer = canvas()
        draw = ImageDraw.Draw(layer)
        pts = []
        for a in range(-70, 71, 4):
            rad = math.radians(a)
            r = 95 + math.sin(rad * 2.2) * 18
            x = cx + math.cos(rad) * r * flip
            y = 255 + math.sin(rad) * 125
            pts.append((x, y))
        draw.polygon(pts, fill=(88, 168, 198, 255))
        radial_blob(layer, cx, 255, 70, 105, (150, 215, 235), (55, 120, 155))
        for i in range(6):
            y = 175 + i * 28
            draw.line((cx - 35 * flip, y, cx + 55 * flip, y + 8), fill=(70, 130, 160, 120), width=3)
        img.alpha_composite(layer)
    trachea = ImageDraw.Draw(img)
    trachea.rounded_rectangle((244, 95, 268, 175), radius=8, fill=(190, 120, 110, 255))
    return soft_shadow(img)


def draw_brain() -> Image.Image:
    img = canvas()
    radial_blob(img, 256, 250, 145, 125, (220, 150, 175), (140, 75, 110))
    draw = ImageDraw.Draw(img)
    for i in range(14):
        y = 145 + i * 16
        wobble = math.sin(i * 0.8) * 18
        draw.arc(
            (150 + wobble, y, 362 - wobble, y + 34),
            start=200,
            end=340,
            fill=(170, 95, 120, 170),
            width=4,
        )
    radial_blob(img, 220, 220, 35, 28, (240, 185, 200), (160, 90, 115), 160)
    radial_blob(img, 295, 235, 30, 24, (240, 185, 200), (160, 90, 115), 140)
    return soft_shadow(img)


def draw_blood() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    drop = [
        (256, 120), (330, 230), (300, 330), (256, 390), (212, 330), (182, 230),
    ]
    draw.polygon(drop, fill=(185, 20, 35, 255))
    radial_blob(img, 245, 250, 70, 95, (255, 90, 90), (140, 10, 25))
    radial_blob(img, 220, 210, 25, 35, (255, 180, 180), (200, 40, 50), 170)
    draw.ellipse((285, 175, 315, 205), fill=(255, 220, 220, 180))
    return soft_shadow(img)


def draw_thyroid() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    for cx in (205, 307):
        radial_blob(img, cx, 255, 58, 72, (170, 205, 240), (90, 140, 195))
    draw.rounded_rectangle((238, 235, 274, 265), radius=8, fill=(120, 165, 210, 255))
    return soft_shadow(img)


def draw_eye() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.ellipse((110, 210, 402, 310), fill=(245, 245, 245, 255), outline=(180, 180, 180, 255), width=3)
    radial_blob(img, 256, 260, 52, 52, (120, 75, 45), (35, 20, 12))
    radial_blob(img, 256, 260, 22, 22, (20, 20, 25), (5, 5, 8))
    draw.ellipse((270, 245, 286, 261), fill=(255, 255, 255, 220))
    draw.arc((110, 170, 402, 250), start=180, end=360, fill=(180, 120, 100, 255), width=8)
    return soft_shadow(img)


def draw_bone() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    shaft = (210, 175, 302, 337)
    draw.rounded_rectangle(shaft, radius=28, fill=(245, 240, 230, 255))
    for cx, cy in ((210, 190), (302, 190), (210, 322), (302, 322)):
        radial_blob(img, cx, cy, 42, 36, (252, 248, 240), (210, 200, 185))
    draw.rounded_rectangle((228, 195, 284, 317), radius=12, fill=(225, 215, 200, 255))
    return soft_shadow(img)


def draw_stomach() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.pieslice((150, 150, 362, 380), start=300, end=120, fill=(210, 130, 115, 255))
    radial_blob(img, 245, 255, 95, 85, (235, 165, 145), (165, 85, 70))
    draw.arc((170, 170, 350, 360), start=310, end=40, fill=(140, 70, 60, 180), width=5)
    return soft_shadow(img)


def draw_pancreas() -> Image.Image:
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.polygon(
        [(150, 255), (220, 220), (340, 235), (380, 270), (330, 300), (210, 295)],
        fill=(220, 175, 120, 255),
    )
    radial_blob(img, 265, 260, 95, 42, (245, 205, 150), (180, 130, 80))
    draw.line((170, 258, 360, 268), fill=(160, 110, 70, 160), width=4)
    return soft_shadow(img)


GENERATORS = {
    "liver": draw_liver,
    "lungs": draw_lungs,
    "brain": draw_brain,
    "blood": draw_blood,
    "thyroid": draw_thyroid,
    "eye": draw_eye,
    "bone": draw_bone,
    "stomach": draw_stomach,
    "pancreas": draw_pancreas,
}


def main() -> None:
    for name, fn in GENERATORS.items():
        out = OUT / f"{name}.png"
        if name == "kidney" and out.exists() and out.stat().st_size > 50000:
            print(f"skip {name} (existing quality asset)")
            continue
        img = fn()
        img.save(out, "PNG", optimize=True)
        print(f"generated {out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
