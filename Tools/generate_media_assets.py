#!/usr/bin/env python3
import json
import math
import os
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
ASSET_ROOT = ROOT / "GuoYueZhiPu" / "Assets.xcassets"
AUDIO_ROOT = ROOT / "GuoYueZhiPu" / "Resources" / "Audio" / "Instruments"
POSTER_SOURCE = ROOT / "Design" / "Source" / "guoyue-gptimage-poster.png"
RESAMPLE = getattr(Image, "Resampling", Image).LANCZOS

PALETTE = {
    "ink": (31, 36, 36),
    "jade": (43, 86, 74),
    "cinnabar": (154, 54, 41),
    "gold": (202, 159, 66),
    "lapis": (54, 76, 120),
    "paper": (244, 239, 228),
}

SECTION_COLORS = {
    "wind": ((42, 100, 91), (197, 159, 74)),
    "plucked": ((148, 59, 43), (217, 174, 82)),
    "bowed": ((52, 72, 118), (205, 158, 73)),
    "percussion": ((48, 48, 45), (164, 57, 43)),
}

ICON_IMAGES = [
    ("iphone", "20x20", 2, "iphone-20@2x.png"),
    ("iphone", "20x20", 3, "iphone-20@3x.png"),
    ("iphone", "29x29", 2, "iphone-29@2x.png"),
    ("iphone", "29x29", 3, "iphone-29@3x.png"),
    ("iphone", "40x40", 2, "iphone-40@2x.png"),
    ("iphone", "40x40", 3, "iphone-40@3x.png"),
    ("iphone", "60x60", 2, "iphone-60@2x.png"),
    ("iphone", "60x60", 3, "iphone-60@3x.png"),
    ("ipad", "20x20", 1, "ipad-20.png"),
    ("ipad", "20x20", 2, "ipad-20@2x.png"),
    ("ipad", "29x29", 1, "ipad-29.png"),
    ("ipad", "29x29", 2, "ipad-29@2x.png"),
    ("ipad", "40x40", 1, "ipad-40.png"),
    ("ipad", "40x40", 2, "ipad-40@2x.png"),
    ("ipad", "76x76", 1, "ipad-76.png"),
    ("ipad", "76x76", 2, "ipad-76@2x.png"),
    ("ipad", "83.5x83.5", 2, "ipad-83.5@2x.png"),
    ("ios-marketing", "1024x1024", 1, "ios-marketing-1024.png"),
]


def ensure_dir(path):
    path.mkdir(parents=True, exist_ok=True)


def write_asset_contents(imageset, filename):
    with open(imageset / "Contents.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "images": [
                    {"filename": filename, "idiom": "universal", "scale": "1x"}
                ],
                "info": {"author": "xcode", "version": 1},
            },
            f,
            indent=2,
            ensure_ascii=False,
        )
        f.write("\n")


def gradient_background(size, start, end):
    img = Image.new("RGB", (size, size), start)
    px = img.load()
    for y in range(size):
        for x in range(size):
            ratio = (x * 0.52 + y * 0.48) / max(size - 1, 1)
            ripple = 0.04 * math.sin((x + y) / size * math.pi * 5)
            t = min(1, max(0, ratio + ripple))
            px[x, y] = tuple(int(start[i] * (1 - t) + end[i] * t) for i in range(3))
    return img


def add_texture(img, strength=14):
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = img.size
    for i in range(0, w + h, 9):
        alpha = int(strength * (0.5 + 0.5 * math.sin(i * 0.31)))
        draw.line([(i, 0), (0, i)], fill=(255, 255, 255, alpha), width=1)
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def draw_stringed_body(draw, cx, cy, scale, fill, accent):
    body = [
        (cx - 82 * scale, cy + 112 * scale),
        (cx - 58 * scale, cy - 20 * scale),
        (cx - 34 * scale, cy - 125 * scale),
        (cx + 18 * scale, cy - 135 * scale),
        (cx + 72 * scale, cy - 8 * scale),
        (cx + 80 * scale, cy + 104 * scale),
    ]
    draw.rounded_rectangle(
        [cx - 54 * scale, cy - 175 * scale, cx + 38 * scale, cy + 142 * scale],
        radius=int(42 * scale),
        fill=fill,
        outline=accent,
        width=max(2, int(7 * scale)),
    )
    draw.polygon(body, fill=fill)
    draw.line(body + [body[0]], fill=accent, width=max(2, int(6 * scale)), joint="curve")
    for offset in [-18, -6, 6, 18]:
        draw.line(
            [(cx + offset * scale, cy - 150 * scale), (cx + offset * scale, cy + 125 * scale)],
            fill=(248, 235, 184, 210),
            width=max(1, int(2 * scale)),
        )
    draw.ellipse(
        [cx - 24 * scale, cy + 8 * scale, cx + 30 * scale, cy + 62 * scale],
        outline=accent,
        width=max(2, int(5 * scale)),
    )


def draw_erhu(draw, cx, cy, scale, fill, accent):
    draw.line(
        [(cx, cy - 175 * scale), (cx, cy + 110 * scale)],
        fill=fill,
        width=max(3, int(8 * scale)),
    )
    draw.rounded_rectangle(
        [cx - 52 * scale, cy + 86 * scale, cx + 52 * scale, cy + 148 * scale],
        radius=int(16 * scale),
        fill=fill,
        outline=accent,
        width=max(2, int(6 * scale)),
    )
    draw.line(
        [(cx - 60 * scale, cy - 12 * scale), (cx + 72 * scale, cy + 88 * scale)],
        fill=accent,
        width=max(2, int(6 * scale)),
    )
    for offset in [-9, 9]:
        draw.line(
            [(cx + offset * scale, cy - 160 * scale), (cx + offset * scale, cy + 138 * scale)],
            fill=(246, 238, 200, 220),
            width=max(1, int(2 * scale)),
        )
    draw.ellipse(
        [cx - 36 * scale, cy - 184 * scale, cx + 36 * scale, cy - 122 * scale],
        fill=accent,
    )


def draw_wind(draw, cx, cy, scale, fill, accent):
    draw.rounded_rectangle(
        [cx - 168 * scale, cy - 32 * scale, cx + 168 * scale, cy + 32 * scale],
        radius=int(22 * scale),
        fill=fill,
        outline=accent,
        width=max(2, int(6 * scale)),
    )
    for i in range(7):
        x = cx - 105 * scale + i * 34 * scale
        draw.ellipse(
            [x - 9 * scale, cy - 9 * scale, x + 9 * scale, cy + 9 * scale],
            fill=(248, 236, 187, 235),
        )
    draw.arc(
        [cx - 148 * scale, cy - 128 * scale, cx + 148 * scale, cy + 128 * scale],
        198,
        342,
        fill=accent,
        width=max(3, int(7 * scale)),
    )


def draw_percussion(draw, cx, cy, scale, fill, accent):
    draw.ellipse(
        [cx - 132 * scale, cy - 72 * scale, cx + 132 * scale, cy + 72 * scale],
        fill=accent,
    )
    draw.rounded_rectangle(
        [cx - 120 * scale, cy - 42 * scale, cx + 120 * scale, cy + 132 * scale],
        radius=int(28 * scale),
        fill=fill,
        outline=accent,
        width=max(2, int(6 * scale)),
    )
    draw.ellipse(
        [cx - 120 * scale, cy - 82 * scale, cx + 120 * scale, cy + 40 * scale],
        fill=(241, 225, 183),
        outline=accent,
        width=max(2, int(7 * scale)),
    )
    draw.line(
        [(cx - 118 * scale, cy - 108 * scale), (cx - 28 * scale, cy - 22 * scale)],
        fill=accent,
        width=max(3, int(8 * scale)),
    )
    draw.line(
        [(cx + 118 * scale, cy - 108 * scale), (cx + 28 * scale, cy - 22 * scale)],
        fill=accent,
        width=max(3, int(8 * scale)),
    )


def draw_instrument_image(instrument):
    section = instrument["section_id"]
    start, end = SECTION_COLORS.get(section, (PALETTE["jade"], PALETTE["gold"]))
    size = 900
    img = gradient_background(size, start, end)
    img = add_texture(img, strength=16)
    draw = ImageDraw.Draw(img)

    draw.rounded_rectangle([64, 64, size - 64, size - 64], radius=68, outline=(255, 247, 210, 62), width=3)
    draw.ellipse([118, 122, 782, 786], fill=(255, 255, 255, 24))
    draw.arc([130, 118, 770, 792], 42, 318, fill=(252, 224, 147, 78), width=10)

    cx, cy = size / 2, size / 2 + 28
    fill = (35, 35, 32, 224)
    accent = (242, 198, 91, 235)

    if section == "wind":
        draw_wind(draw, cx, cy, 1.52, fill, accent)
    elif section == "plucked":
        if instrument["id"] in {"guzheng", "yangqin"}:
            draw.rounded_rectangle([156, 352, 744, 574], radius=42, fill=fill, outline=accent, width=10)
            for i in range(10):
                y = 380 + i * 18
                draw.line([(190, y), (708, y + 72)], fill=(248, 237, 190, 210), width=3)
            draw.arc([170, 264, 730, 660], 190, 350, fill=accent, width=8)
        elif instrument["id"] == "konghou":
            draw.arc([230, 160, 720, 765], 90, 292, fill=fill, width=30)
            draw.line([(278, 680), (720, 680)], fill=fill, width=26)
            for i in range(11):
                x = 310 + i * 34
                draw.line([(x, 250 + i * 7), (x + 110, 680)], fill=(248, 237, 190, 210), width=2)
        else:
            draw_stringed_body(draw, cx, cy, 1.42, fill, accent)
    elif section == "bowed":
        if instrument["id"] == "gehu":
            draw_stringed_body(draw, cx, cy + 16, 1.55, fill, accent)
        else:
            draw_erhu(draw, cx, cy, 1.55, fill, accent)
    else:
        if instrument["id"] in {"luo", "bo"}:
            draw.ellipse([198, 230, 702, 734], fill=accent, outline=fill, width=14)
            draw.ellipse([350, 382, 550, 582], fill=(246, 226, 160), outline=fill, width=8)
            draw.line([(220, 680), (690, 250)], fill=(255, 248, 218, 110), width=8)
        elif instrument["id"] == "muyu":
            draw.rounded_rectangle([250, 292, 650, 638], radius=104, fill=fill, outline=accent, width=12)
            draw.ellipse([358, 380, 542, 520], fill=(246, 226, 160), outline=accent, width=5)
            draw.line([(640, 240), (520, 372)], fill=accent, width=12)
        else:
            draw_percussion(draw, cx, cy, 1.35, fill, accent)

    img = img.filter(ImageFilter.UnsharpMask(radius=1.2, percent=115, threshold=3))
    return img.convert("RGB")


def draw_brand_art(size=1600):
    img = gradient_background(size, PALETTE["ink"], PALETTE["jade"])
    img = add_texture(img, strength=18)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, int(size * 0.68), size, size], fill=(18, 22, 22, 120))
    for i in range(9):
        x = size * (0.12 + i * 0.095)
        h = size * (0.16 + 0.08 * math.sin(i * 1.7))
        draw.rounded_rectangle(
            [x, size * 0.58 - h, x + size * 0.024, size * 0.64],
            radius=int(size * 0.012),
            fill=(236, 198, 112, 195),
        )
    draw.arc([size * 0.11, size * 0.20, size * 0.88, size * 0.84], 196, 344, fill=(202, 159, 66, 210), width=int(size * 0.018))
    draw.line([size * 0.30, size * 0.25, size * 0.70, size * 0.72], fill=(245, 231, 190, 210), width=int(size * 0.010))
    draw.ellipse([size * 0.62, size * 0.28, size * 0.78, size * 0.44], fill=(154, 54, 41, 220))
    draw.rounded_rectangle([size * 0.22, size * 0.66, size * 0.78, size * 0.78], radius=int(size * 0.05), fill=(31, 36, 36, 210), outline=(202, 159, 66, 200), width=int(size * 0.007))
    return img.convert("RGB")


def draw_app_icon(size):
    img = gradient_background(size, PALETTE["jade"], PALETTE["ink"])
    img = add_texture(img, strength=10)
    draw = ImageDraw.Draw(img)
    s = size / 1024
    draw.ellipse([96 * s, 88 * s, 928 * s, 928 * s], fill=(255, 255, 255, 22))
    draw.arc([126 * s, 128 * s, 900 * s, 918 * s], 202, 338, fill=PALETTE["gold"], width=max(3, int(28 * s)))
    draw.line([(350 * s, 212 * s), (650 * s, 814 * s)], fill=(246, 228, 172), width=max(3, int(26 * s)))
    draw.line([(468 * s, 190 * s), (468 * s, 818 * s)], fill=(28, 31, 30), width=max(5, int(46 * s)))
    draw.rounded_rectangle([360 * s, 690 * s, 604 * s, 840 * s], radius=int(48 * s), fill=(29, 31, 29), outline=PALETTE["gold"], width=max(2, int(18 * s)))
    draw.ellipse([375 * s, 150 * s, 565 * s, 310 * s], fill=PALETTE["cinnabar"], outline=PALETTE["gold"], width=max(2, int(12 * s)))
    for dx in [-34, 34]:
        draw.line([(468 * s + dx * s, 205 * s), (468 * s + dx * s, 822 * s)], fill=(248, 238, 196), width=max(1, int(7 * s)))
    return img.convert("RGB")


def poster_art(size):
    source = Image.open(POSTER_SOURCE).convert("RGB")
    return ImageOps.fit(source, (size, size), method=RESAMPLE, centering=(0.5, 0.5))


def write_app_icons():
    appicon = ASSET_ROOT / "AppIcon.appiconset"
    ensure_dir(appicon)
    images = []
    for idiom, point_size, scale, filename in ICON_IMAGES:
        pixels = int(float(point_size.split("x")[0]) * scale)
        icon = poster_art(pixels) if POSTER_SOURCE.exists() else draw_app_icon(pixels)
        icon.save(appicon / filename)
        entry = {
            "idiom": idiom,
            "size": point_size,
            "scale": f"{scale}x",
            "filename": filename,
        }
        images.append(entry)
    with open(appicon / "Contents.json", "w", encoding="utf-8") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")


def waveform_value(kind, phase, idx):
    if kind == "sawtooth":
        normalized = phase / (2 * math.pi)
        return 2.0 * (normalized - math.floor(normalized + 0.5))
    if kind == "triangle":
        normalized = phase / (2 * math.pi)
        return 2.0 * abs(2.0 * (normalized - math.floor(normalized + 0.5))) - 1.0
    if kind == "square":
        return 1.0 if math.sin(phase) >= 0 else -1.0
    if kind == "metallic":
        return 0.56 * math.sin(phase) + 0.26 * math.sin(phase * 2.67) + 0.14 * math.sin(phase * 5.31)
    if kind == "noise":
        pseudo = math.sin(idx * 12.9898 + 78.233) * 43758.5453
        return (pseudo - math.floor(pseudo)) * 2 - 1
    return math.sin(phase)


def write_audio(instrument):
    ensure_dir(AUDIO_ROOT)
    sample_rate = 44100
    duration = 2.15
    frames = int(sample_rate * duration)
    freq = float(instrument["pitch_frequency_hz"])
    kind = instrument["audio_waveform_type"]
    path = AUDIO_ROOT / f"{instrument['id']}.wav"

    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        raw = bytearray()
        for i in range(frames):
            t = i / sample_rate
            attack = min(t / 0.05, 1.0)
            release = min((duration - t) / 0.45, 1.0)
            pulse = 0.86 + 0.14 * math.sin(2 * math.pi * 5.3 * t)
            envelope = max(0.0, min(attack, release)) * pulse
            phase = 2 * math.pi * freq * t
            value = waveform_value(kind, phase, i)
            value += 0.18 * waveform_value(kind, phase * 2.01, i + 3)
            value += 0.08 * math.sin(2 * math.pi * freq * 0.5 * t)
            sample = int(max(-1, min(1, value * envelope * 0.36)) * 32767)
            raw.extend(sample.to_bytes(2, "little", signed=True))
        wav.writeframes(raw)


def main():
    with open(DATA_PATH, encoding="utf-8") as f:
        data = json.load(f)

    write_app_icons()

    brand_set = ASSET_ROOT / "brand_hero.imageset"
    ensure_dir(brand_set)
    brand_art = poster_art(1800) if POSTER_SOURCE.exists() else draw_brand_art(1600)
    brand_art.save(brand_set / "brand_hero.png")
    write_asset_contents(brand_set, "brand_hero.png")

    for instrument in data["instruments"]:
        image_name = f"instrument_{instrument['id']}"
        imageset = ASSET_ROOT / f"{image_name}.imageset"
        ensure_dir(imageset)
        draw_instrument_image(instrument).save(imageset / f"{image_name}.png")
        write_asset_contents(imageset, f"{image_name}.png")
        write_audio(instrument)

    print(f"Generated {len(data['instruments'])} instrument images, audio samples, and app icons.")


if __name__ == "__main__":
    main()
