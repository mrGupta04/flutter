"""Remove white backgrounds from organ JPGs and export transparent PNGs."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

SRC = Path(__file__).resolve().parents[1] / "assets" / "images" / "organ"
THRESHOLD = 232
SOFT_RANGE = 18


def alpha_for_pixel(r: int, g: int, b: int) -> int:
    """Map near-white pixels to transparent with soft edges."""
    whiteness = min(r, g, b)
    if whiteness >= THRESHOLD + SOFT_RANGE:
        return 0
    if whiteness <= THRESHOLD - SOFT_RANGE:
        return 255
    # Soft transition on edges.
    t = (whiteness - (THRESHOLD - SOFT_RANGE)) / (2 * SOFT_RANGE)
    return int((1 - t) * 255)


def remove_background(src: Path, dest: Path) -> None:
    img = Image.open(src).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            alpha = alpha_for_pixel(r, g, b)
            if alpha < 255:
                pixels[x, y] = (r, g, b, min(a, alpha))
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest, "PNG", optimize=True)
    print(f"{src.name} -> {dest.name} ({dest.stat().st_size // 1024} KB)")


def main() -> None:
    for src in sorted(SRC.glob("*.jpg")):
        dest = SRC / f"{src.stem}.png"
        remove_background(src, dest)
    print("Done.")


if __name__ == "__main__":
    main()
