"""Download realistic anatomical organ PNGs via Wikimedia Commons API."""
import io
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets" / "images" / "organs"
OUT.mkdir(parents=True, exist_ok=True)

API = "https://commons.wikimedia.org/w/api.php"

# Blausen Medical Communications — CC BY 3.0
FILES = {
    "kidney": "Blausen 0592 KidneyAnatomy 01.png",
    "liver": "Blausen 0747 LiverAnatomy 01.png",
    "lungs": "Blausen 0625 LungAnatomy 01.png",
    "brain": "Brain Anatomy (Sagittal).png",
    "stomach": "Blausen 0601 StomachAnatomy 01.png",
    "thyroid": "Blausen 0530 ThyroidAnatomy 01.png",
    "eye": "Blausen 0361 EyeAnatomy 01.png",
    "bone": "Blausen 0227 BoneAnatomy 01.png",
    "pancreas": "Blausen 0699 PancreasAnatomy 01.png",
    "blood": "Blausen 0483 HighBloodPressure 01.png",
}

# Fallback filenames if primary 404
FALLBACKS = {
    "liver": "Blausen 0316 DigestiveSystem.png",
    "lungs": "Respiratory System (Illustration).png",
    "brain": "Brain Anatomy - Mid-Fore-HindBrain.png",
    "blood": "Blausen 0325 BloodCells.png",
    "bone": "Blausen 0227 BoneAnatomy 02.png",
    "pancreas": "Blausen 0699 PancreasAnatomy 02.png",
}

TARGET = 512
HEADERS = {"User-Agent": "HealthAppOrganDownloader/1.0 (demo project; contact: dev@local)"}


def get_image_url(filename: str) -> str | None:
    params = urllib.parse.urlencode(
        {
            "action": "query",
            "titles": f"File:{filename}",
            "prop": "imageinfo",
            "iiprop": "url",
            "format": "json",
        }
    )
    req = urllib.request.Request(f"{API}?{params}", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode())
    pages = data.get("query", {}).get("pages", {})
    for page in pages.values():
        info = page.get("imageinfo", [])
        if info:
            return info[0]["url"]
    return None


def download_bytes(url: str) -> bytes:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def process_image(data: bytes) -> Image.Image:
    img = Image.open(io.BytesIO(data)).convert("RGBA")
    # Remove near-white background for Blausen illustrations
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r > 240 and g > 240 and b > 240:
                pixels[x, y] = (r, g, b, 0)
    img.thumbnail((TARGET, TARGET), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (TARGET, TARGET), (0, 0, 0, 0))
    x = (TARGET - img.width) // 2
    y = (TARGET - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def download_organ(name: str, filename: str) -> bool:
    print(f"Fetching {name} ({filename})...")
    url = get_image_url(filename)
    if not url and name in FALLBACKS:
        fallback = FALLBACKS[name]
        print(f"  Trying fallback: {fallback}")
        time.sleep(2)
        url = get_image_url(fallback)
    if not url:
        print(f"  FAILED: no URL for {name}")
        return False
    time.sleep(1.5)
    data = download_bytes(url)
    canvas = process_image(data)
    out = OUT / f"{name}.png"
    canvas.save(out, "PNG", optimize=True)
    print(f"  -> {out} ({out.stat().st_size // 1024} KB)")
    return True


def main() -> None:
    for name, filename in FILES.items():
        try:
            download_organ(name, filename)
        except Exception as e:
            print(f"  ERROR {name}: {e}")
            if name in FALLBACKS:
                try:
                    time.sleep(2)
                    download_organ(name, FALLBACKS[name])
                except Exception as e2:
                    print(f"  FALLBACK ERROR {name}: {e2}")
    print("Done.")


if __name__ == "__main__":
    main()
