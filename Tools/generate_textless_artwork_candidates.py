#!/usr/bin/env python3
import json
import math
import shutil
import struct
from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
CANDIDATE_ROOT = ROOT / "Design" / "Review" / "ArtworkCandidates"
MANIFEST_PATH = CANDIDATE_ROOT / "candidate_manifest.json"
APPROVAL_DRAFT_ROOT = CANDIDATE_ROOT / "approval_drafts"
SIZE = 900
PAPER = (244, 239, 228)
SHADOW = (226, 219, 201)
INK = (55, 35, 24)
WOOD = (125, 72, 36)
DARK_WOOD = (83, 49, 30)
LIGHT_WOOD = (193, 143, 72)
SKIN = (198, 171, 123)
GOLD = (191, 150, 74)
BELL = (181, 137, 58)
PIPE = (191, 132, 51)

ORDER = ["banhu", "erhu", "gaohu", "gehu", "sheng", "suona", "zhonghu"]


def digest(path):
    h = sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def png_size(path):
    with path.open("rb") as f:
        header = f.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"Not PNG: {path}")
    return struct.unpack(">II", header[16:24])


def base():
    img = Image.new("RGB", (SIZE, SIZE), PAPER)
    draw = ImageDraw.Draw(img)
    draw.ellipse([140, 705, 760, 805], fill=SHADOW)
    return img, draw


def line(draw, points, fill=INK, width=5):
    draw.line(points, fill=fill, width=width, joint="curve")


def polygon_regular(cx, cy, r, sides=8, rotation=math.pi / 8):
    return [
        (
            cx + math.cos(rotation + i * 2 * math.pi / sides) * r,
            cy + math.sin(rotation + i * 2 * math.pi / sides) * r,
        )
        for i in range(sides)
    ]


def strings_and_bow(draw, cx, top, bottom, bow_x, bow_top, bow_bottom):
    for xoff in [-9, 9]:
        line(draw, [(cx + xoff, top), (cx + xoff, bottom)], fill=(36, 28, 22), width=2)
    line(draw, [(bow_x, bow_top), (bow_x + 28, bow_bottom)], fill=DARK_WOOD, width=6)
    line(draw, [(bow_x + 17, bow_top), (bow_x + 54, bow_bottom)], fill=(236, 229, 204), width=3)


def pegs(draw, cx, y, length=90):
    line(draw, [(cx, y), (cx - length, y - 22)], fill=DARK_WOOD, width=18)
    draw.ellipse([cx - length - 25, y - 47, cx - length + 25, y + 3], fill=WOOD, outline=INK, width=4)
    line(draw, [(cx, y + 45), (cx + length, y + 20)], fill=DARK_WOOD, width=18)
    draw.ellipse([cx + length - 25, y - 5, cx + length + 25, y + 45], fill=WOOD, outline=INK, width=4)


def draw_huqin(kind):
    img, draw = base()
    specs = {
        "gaohu": {"cx": 450, "body": (70, 50), "top": 205, "bottom": 650, "bow": 590, "body_y": 665, "neck_w": 16},
        "erhu": {"cx": 450, "body": (98, 70), "top": 190, "bottom": 675, "bow": 600, "body_y": 665, "neck_w": 20},
        "zhonghu": {"cx": 450, "body": (120, 86), "top": 170, "bottom": 690, "bow": 615, "body_y": 660, "neck_w": 24},
    }[kind]
    cx = specs["cx"]
    line(draw, [(cx, specs["top"]), (cx, specs["bottom"])], fill=DARK_WOOD, width=specs["neck_w"])
    pegs(draw, cx, specs["top"] + 65)
    w, h = specs["body"]
    draw.rounded_rectangle(
        [cx - w / 2, specs["body_y"] - h / 2, cx + w / 2, specs["body_y"] + h / 2],
        radius=18,
        fill=WOOD,
        outline=INK,
        width=5,
    )
    draw.ellipse(
        [cx - w * 0.34, specs["body_y"] - h * 0.34, cx + w * 0.34, specs["body_y"] + h * 0.34],
        fill=SKIN,
        outline=INK,
        width=4,
    )
    strings_and_bow(draw, cx, specs["top"] + 8, specs["body_y"] + h / 2 - 12, specs["bow"], 300, 760)
    return img


def draw_banhu():
    img, draw = base()
    cx = 450
    line(draw, [(cx, 185), (cx, 690)], fill=DARK_WOOD, width=18)
    pegs(draw, cx, 260, length=78)
    body_cy = 672
    draw.ellipse([cx - 72, body_cy - 62, cx + 72, body_cy + 62], fill=WOOD, outline=INK, width=5)
    draw.polygon(polygon_regular(cx, body_cy, 52, sides=10), fill=LIGHT_WOOD, outline=INK)
    draw.rectangle([cx - 28, body_cy - 36, cx + 28, body_cy + 36], fill=(215, 182, 118), outline=INK, width=3)
    strings_and_bow(draw, cx, 195, body_cy + 62, 595, 310, 742)
    return img


def draw_gehu():
    img, draw = base()
    cx = 450
    body_cy = 610
    draw.ellipse([cx - 140, body_cy - 150, cx + 140, body_cy + 150], fill=WOOD, outline=INK, width=7)
    draw.ellipse([cx - 85, body_cy - 92, cx + 85, body_cy + 92], fill=SKIN, outline=INK, width=5)
    line(draw, [(cx, 155), (cx, body_cy + 145)], fill=DARK_WOOD, width=24)
    line(draw, [(cx, body_cy + 145), (cx, 805)], fill=INK, width=5)
    pegs(draw, cx, 235, length=95)
    for xoff in [-18, -6, 6, 18]:
        line(draw, [(cx + xoff, 175), (cx + xoff, body_cy + 130)], fill=(36, 28, 22), width=2)
    line(draw, [(620, 300), (660, 760)], fill=DARK_WOOD, width=7)
    line(draw, [(642, 300), (690, 760)], fill=(236, 229, 204), width=4)
    return img


def draw_suona():
    img, draw = base()
    cx = 450
    body = [(cx - 28, 270), (cx + 28, 270), (cx + 56, 610), (cx - 56, 610)]
    draw.polygon(body, fill=WOOD, outline=INK)
    line(draw, [(cx - 12, 205), (cx - 28, 270)], fill=GOLD, width=14)
    draw.polygon([(cx - 31, 178), (cx + 31, 178), (cx + 22, 225), (cx - 22, 225)], fill=(215, 171, 88), outline=INK)
    for i in range(5):
        y = 330 + i * 56
        draw.ellipse([cx - 13, y - 13, cx + 13, y + 13], fill=INK)
    draw.ellipse([cx - 132, 590, cx + 132, 800], fill=BELL, outline=INK, width=7)
    draw.ellipse([cx - 86, 640, cx + 86, 752], fill=(111, 77, 43))
    return img


def draw_sheng():
    img, draw = base()
    cx = 450
    heights = [520, 610, 470, 645, 430, 660, 455, 620, 510, 575, 690, 545, 605, 490, 640]
    start_x = cx - 175
    for i, top in enumerate(heights):
        x = start_x + i * 25
        line(draw, [(x, top), (x, 690)], fill=PIPE, width=13)
        draw.ellipse([x - 8, top - 7, x + 8, top + 7], fill=(232, 176, 89), outline=INK, width=1)
    draw.ellipse([cx - 135, 610, cx + 135, 790], fill=WOOD, outline=INK, width=6)
    draw.ellipse([cx - 92, 640, cx + 92, 755], fill=(120, 73, 38), outline=INK, width=3)
    line(draw, [(cx + 88, 720), (cx + 230, 780)], fill=GOLD, width=22)
    draw.polygon([(cx + 215, 765), (cx + 280, 795), (cx + 222, 812)], fill=GOLD, outline=INK)
    return img


def draw_candidate(instrument_id):
    if instrument_id in {"erhu", "gaohu", "zhonghu"}:
        return draw_huqin(instrument_id)
    if instrument_id == "banhu":
        return draw_banhu()
    if instrument_id == "gehu":
        return draw_gehu()
    if instrument_id == "suona":
        return draw_suona()
    if instrument_id == "sheng":
        return draw_sheng()
    raise ValueError(instrument_id)


def build_contact_sheet(items):
    thumb_w, thumb_h = 220, 220
    margin_x, margin_y = 24, 26
    label_h = 24
    cols = 4
    rows = 2
    sheet = Image.new("RGB", (1000, 600), PAPER)
    draw = ImageDraw.Draw(sheet)
    for index, item in enumerate(items):
        row, col = divmod(index, cols)
        x = margin_x + col * 244
        y = margin_y + row * 286
        candidate = Image.open(ROOT / item["path"]).convert("RGB")
        sheet.paste(candidate.resize((thumb_w, thumb_h)), (x, y))
        draw.text((x, y + thumb_h + 8), item["instrument_id"], fill=INK)
    return sheet


def main():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    items_by_id = {item["instrument_id"]: item for item in manifest["items"]}

    for instrument_id in ORDER:
        item = items_by_id[instrument_id]
        target = ROOT / item["path"]
        archive = target.with_name(target.stem + "_annotated_reference.png")
        if target.exists() and not archive.exists():
            shutil.copy2(target, archive)
        image = draw_candidate(instrument_id)
        image.save(target)
        item["sha256"] = digest(target)
        item["size"] = "900x900"
        item["annotation_status"] = "no_internal_text_labels"
        item["annotated_reference_path"] = str(archive.relative_to(ROOT))

        draft_path = APPROVAL_DRAFT_ROOT / f"{instrument_id}.approval.draft.json"
        if draft_path.exists():
            draft = json.loads(draft_path.read_text(encoding="utf-8"))
            draft["candidate_path"] = item["path"]
            draft["candidate_sha256"] = item["sha256"]
            draft["candidate_size"] = item["size"]
            confirmations = draft.setdefault("confirmations", {})
            confirmations["no_visible_internal_text_labels"] = True
            draft_path.write_text(json.dumps(draft, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    ordered_items = [items_by_id[instrument_id] for instrument_id in ORDER]
    contact_sheet = build_contact_sheet(ordered_items)
    contact_path = ROOT / manifest["contact_sheet"]["path"]
    contact_sheet.save(contact_path)
    manifest["contact_sheet"]["sha256"] = digest(contact_path)
    manifest["contact_sheet"]["size"] = f"{png_size(contact_path)[0]}x{png_size(contact_path)[1]}"
    manifest["updated_at"] = "2026-06-15"
    manifest["status"] = "textless_candidates_pending_professional_review"
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Generated textless high-risk artwork candidates.")


if __name__ == "__main__":
    main()
