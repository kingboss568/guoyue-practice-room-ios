#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
CREDITS = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedPhotos"
    / "manifests"
    / "commons_photo_credits.json"
)
SELECTION = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedPhotos"
    / "manifests"
    / "photo_source_selection.json"
)
ARTWORK_CATALOG = ROOT / "GuoYueZhiPu" / "Models" / "ArtworkReview.swift"
SOURCE_CATALOG = ROOT / "GuoYueZhiPu" / "Models" / "AssetCredits.swift"
COMPONENTS = ROOT / "GuoYueZhiPu" / "Views" / "Components.swift"
INSTRUMENTS_VIEW = ROOT / "GuoYueZhiPu" / "Views" / "InstrumentsView.swift"
ASSET_CREDITS_VIEW = ROOT / "GuoYueZhiPu" / "Views" / "AssetCreditsView.swift"
PBXPROJ = ROOT / "GuoYueZhiPu.xcodeproj" / "project.pbxproj"

SOURCE_VERIFIED_STATUSES = {
    "approved_after_source_and_internal_visual_qc",
    "approved_after_professional_review",
}


def load_json(file_path):
    with file_path.open(encoding="utf-8") as handle:
        return json.load(handle)


def sha256(file_path):
    digest = hashlib.sha256()
    with file_path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    failures = []

    data = load_json(DATA)
    credits = load_json(CREDITS)
    selection = load_json(SELECTION)
    artwork_catalog = ARTWORK_CATALOG.read_text(encoding="utf-8")
    source_catalog = SOURCE_CATALOG.read_text(encoding="utf-8")
    components = COMPONENTS.read_text(encoding="utf-8")
    instruments_view = INSTRUMENTS_VIEW.read_text(encoding="utf-8")
    asset_credits_view = ASSET_CREDITS_VIEW.read_text(encoding="utf-8")
    pbxproj = PBXPROJ.read_text(encoding="utf-8")

    instruments = data.get("instruments", [])
    names_by_id = {item.get("id"): item.get("name_zh") for item in instruments}
    expected_ids = set(names_by_id)
    credits_by_id = {
        item.get("instrument_id"): item for item in credits.get("results", [])
    }
    blocked_by_id = {
        item.get("instrument_id"): item for item in credits.get("blocked", [])
    }
    selection_by_id = {
        item.get("instrument_id"): item for item in selection.get("instruments", [])
    }

    represented_ids = set(credits_by_id) | set(blocked_by_id)
    if represented_ids != expected_ids:
        failures.append(
            "verified photo manifest coverage mismatch: "
            + f"got {sorted(represented_ids)}, expected {sorted(expected_ids)}"
        )
    if set(credits_by_id) & set(blocked_by_id):
        failures.append("an instrument cannot be both verified and blocked")
    if set(selection_by_id) != expected_ids:
        failures.append("photo source selection must cover every app instrument exactly once")

    for instrument_id, credit in sorted(credits_by_id.items()):
        name_zh = names_by_id.get(instrument_id, "")
        selected = selection_by_id.get(instrument_id, {})
        if selected.get("status") not in SOURCE_VERIFIED_STATUSES:
            failures.append(f"{instrument_id}: source/visual QC status is not current")
        for key in ["source_page", "license", "app_asset", "app_asset_sha256"]:
            if not str(credit.get(key, "")).strip():
                failures.append(f"{instrument_id}: photo credit field {key} is required")

        asset_rel = str(credit.get("app_asset", ""))
        asset_file = ROOT / asset_rel
        if asset_rel and not asset_file.exists():
            failures.append(f"{instrument_id}: app photo asset is missing: {asset_rel}")
        elif asset_rel and sha256(asset_file) != credit.get("app_asset_sha256"):
            failures.append(f"{instrument_id}: app photo SHA-256 does not match manifest")

        if f'commons("{instrument_id}", "{name_zh}"' not in source_catalog:
            failures.append(f"{instrument_id}: missing from PhotoSourceCatalog")
        if f'("{instrument_id}", "{name_zh}")' not in artwork_catalog:
            failures.append(f"{instrument_id}: missing from verified ArtworkReviewCatalog")

    for instrument_id in sorted(blocked_by_id):
        selected = selection_by_id.get(instrument_id, {})
        if not str(selected.get("status", "")).startswith("blocked_"):
            failures.append(f"{instrument_id}: blocked photo status is missing")
        if f'instrumentID: "{instrument_id}"' not in artwork_catalog:
            failures.append(f"{instrument_id}: blocked ArtworkReviewCatalog record is missing")
        if "blockedInstrumentIDs" not in source_catalog or f'"{instrument_id}"' not in source_catalog:
            failures.append(f"{instrument_id}: missing from PhotoSourceCatalog blocked set")

    required_ui_tokens = {
        "Components.swift": ["PhotoSourceCatalog.source", "實拍授權待補"],
        "InstrumentsView.swift": ["ArtworkReviewDisclosureCard", "素材來源與授權"],
        "AssetCreditsView.swift": [
            "PhotoSourceCatalog.verifiedSources",
            "已核對樂器實拍",
            "不得視為可送審素材",
        ],
    }
    ui_texts = {
        "Components.swift": components,
        "InstrumentsView.swift": instruments_view,
        "AssetCreditsView.swift": asset_credits_view,
    }
    for filename, tokens in required_ui_tokens.items():
        for token in tokens:
            if token not in ui_texts[filename]:
                failures.append(f"{filename} missing artwork disclosure token: {token}")

    if "ArtworkReview.swift in Sources" not in pbxproj:
        failures.append("Xcode project missing ArtworkReview.swift in Sources")

    print(
        "Artwork status disclosure: "
        + f"{len(credits_by_id)} verified real photo(s), "
        + f"{len(blocked_by_id)} blocked instrument(s)."
    )

    if failures:
        print("\nArtwork status disclosure check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Artwork status disclosure check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
