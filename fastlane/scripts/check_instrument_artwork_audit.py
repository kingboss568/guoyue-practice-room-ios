#!/usr/bin/env python3
import argparse
import hashlib
import json
from pathlib import Path


SOURCE_AND_VISUAL_QC_APPROVED = "approved_after_source_and_internal_visual_qc"
PROFESSIONALLY_APPROVED = "approved_after_professional_review"
EXPECTED_BLOCKED_IDS = {"paigu"}


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
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    data_path = root / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
    selection_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedPhotos"
        / "manifests"
        / "photo_source_selection.json"
    )
    credits_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedPhotos"
        / "manifests"
        / "commons_photo_credits.json"
    )

    failures = []
    warnings = []
    data = load_json(data_path)
    selection = load_json(selection_path)
    credits = load_json(credits_path)

    instrument_ids = {item.get("id") for item in data.get("instruments", [])}
    selection_by_id = {
        item.get("instrument_id"): item for item in selection.get("instruments", [])
    }
    credit_by_id = {
        item.get("instrument_id"): item for item in credits.get("results", [])
    }
    blocked_by_id = {
        item.get("instrument_id"): item for item in credits.get("blocked", [])
    }

    if set(selection_by_id) != instrument_ids:
        failures.append("Photo selection manifest must cover all 23 instruments")
    if (set(credit_by_id) | set(blocked_by_id)) != instrument_ids:
        failures.append("Photo credit and blocked manifests must cover all 23 instruments")

    source_verified = []
    professionally_approved = []
    blocked = []

    for instrument_id in sorted(instrument_ids):
        selected = selection_by_id.get(instrument_id, {})
        status = selected.get("status")
        if str(status).startswith("blocked_"):
            blocked.append(instrument_id)
            if instrument_id not in blocked_by_id:
                failures.append(f"{instrument_id}: blocked manifest entry is missing")
            continue

        if status not in {SOURCE_AND_VISUAL_QC_APPROVED, PROFESSIONALLY_APPROVED}:
            failures.append(f"{instrument_id}: unknown photo review status {status}")
            continue
        credit = credit_by_id.get(instrument_id)
        if not credit:
            failures.append(f"{instrument_id}: verified photo credit is missing")
            continue

        asset_rel = str(credit.get("app_asset", ""))
        asset_file = root / asset_rel
        if not asset_rel or not asset_file.exists():
            failures.append(f"{instrument_id}: verified app photo is missing: {asset_rel}")
            continue
        if sha256(asset_file) != credit.get("app_asset_sha256"):
            failures.append(f"{instrument_id}: verified app photo SHA-256 mismatch")
            continue
        source_verified.append(instrument_id)
        if status == PROFESSIONALLY_APPROVED:
            professionally_approved.append(instrument_id)

    print(f"Verified real-instrument photos: {len(source_verified)}/{len(instrument_ids)}")
    print(
        "Optional named professional photo reviews: "
        + f"{len(professionally_approved)}/{len(source_verified)}"
    )
    print(f"Blocked exact-photo gaps: {len(blocked)}")

    if set(blocked) != EXPECTED_BLOCKED_IDS:
        failures.append(
            "Blocked photo set must remain the explicitly disclosed paigu gap: "
            + f"got {sorted(blocked)}, expected {sorted(EXPECTED_BLOCKED_IDS)}"
        )
    elif blocked:
        warnings.append(
            "Paigu keeps an explicit no-photo placeholder and official real-instrument reference; no substitute image is bundled."
        )

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nInstrument artwork audit failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Instrument artwork audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
