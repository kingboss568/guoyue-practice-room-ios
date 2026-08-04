#!/usr/bin/env python3
"""Build the review contact sheet from the verified-photo manifest."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "Design/Source/VerifiedPhotos/manifests/commons_photo_credits.json"
OUTPUT = ROOT / "Design/Review/PhotoQC/commons-instrument-contact-sheet.jpg"
FONT_CANDIDATES = [
    Path("/System/Library/Fonts/PingFang.ttc"),
    Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in FONT_CANDIDATES:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


def main() -> int:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    entries = manifest["results"]
    columns = 5
    cell_width = 300
    cell_height = 350
    rows = math.ceil(len(entries) / columns)
    background = "#F3EFE6"
    sheet = Image.new("RGB", (columns * cell_width, rows * cell_height), background)
    draw = ImageDraw.Draw(sheet)
    font = load_font(25)

    for index, entry in enumerate(entries):
        row, column = divmod(index, columns)
        origin_x = column * cell_width
        origin_y = row * cell_height
        source = ROOT / entry["app_asset"]
        with Image.open(source) as opened:
            photo = ImageOps.contain(opened.convert("RGB"), (250, 250))
        image_x = origin_x + (cell_width - photo.width) // 2
        image_y = origin_y + 20 + (250 - photo.height) // 2
        sheet.paste(photo, (image_x, image_y))

        label = f"{entry['name_zh']} {entry['instrument_id']}"
        bounds = draw.textbbox((0, 0), label, font=font)
        label_width = bounds[2] - bounds[0]
        draw.text(
            (origin_x + (cell_width - label_width) / 2, origin_y + 285),
            label,
            fill="#202423",
            font=font,
        )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT, format="JPEG", quality=90, optimize=True)
    print(f"Wrote {len(entries)} photos to {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
