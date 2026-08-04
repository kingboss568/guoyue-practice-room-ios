#!/usr/bin/env python3
import json
from pathlib import Path


VALID_STATUSES = {
    "procure_real_recording",
    "candidate_license_review",
    "candidate_original_download_required",
    "candidate_quality_review",
    "approved",
}

REQUIRED_GLOBAL_CONFIRMATIONS = {
    "VST or sample library playback",
    "AI-generated instrument tone",
    "Suno/Udio/generative music output",
    "YouTube/CD/streaming extraction",
}


def main():
    root = Path(__file__).resolve().parents[2]
    data_path = root / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
    manifest_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedAudio"
        / "manifests"
        / "verified_audio_sources.json"
    )
    tracker_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedAudio"
        / "procurement"
        / "audio_procurement_tracker.json"
    )
    checklist_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedAudio"
        / "procurement"
        / "recording_delivery_checklist.json"
    )

    with data_path.open(encoding="utf-8") as f:
        data = json.load(f)
    with manifest_path.open(encoding="utf-8") as f:
        manifest = json.load(f)
    with tracker_path.open(encoding="utf-8") as f:
        tracker = json.load(f)
    with checklist_path.open(encoding="utf-8") as f:
        checklist = json.load(f)

    instrument_ids = {item["id"] for item in data.get("instruments", [])}
    approved_ids = {
        item["instrument_id"]
        for item in manifest.get("approved", [])
        if item.get("status") == "approved"
    }
    open_ids = instrument_ids - approved_ids
    manifest_open_ids = set(manifest.get("open_instrument_ids", []))
    tracker_items = tracker.get("items", [])
    tracker_by_id = {item.get("instrument_id"): item for item in tracker_items}
    checklist_items = checklist.get("items", [])
    checklist_by_id = {item.get("instrument_id"): item for item in checklist_items}

    failures = []

    if manifest_open_ids != open_ids:
        failures.append(
            "open_instrument_ids must match instruments without approved audio: "
            + f"manifest={len(manifest_open_ids)} expected={len(open_ids)}"
        )

    missing_tracker = sorted(open_ids - set(tracker_by_id))
    if missing_tracker:
        failures.append("Procurement tracker missing open instruments: " + ", ".join(missing_tracker))

    missing_checklist = sorted(open_ids - set(checklist_by_id))
    if missing_checklist:
        failures.append("Delivery checklist missing open instruments: " + ", ".join(missing_checklist))

    unknown_tracker = sorted(set(tracker_by_id) - instrument_ids)
    if unknown_tracker:
        failures.append("Procurement tracker has unknown instruments: " + ", ".join(unknown_tracker))

    unknown_checklist = sorted(set(checklist_by_id) - instrument_ids)
    if unknown_checklist:
        failures.append("Delivery checklist has unknown instruments: " + ", ".join(unknown_checklist))

    not_allowed = set(tracker.get("global_requirements", {}).get("not_allowed", []))
    missing_bans = sorted(REQUIRED_GLOBAL_CONFIRMATIONS - not_allowed)
    if missing_bans:
        failures.append("Procurement tracker missing required banned source types: " + ", ".join(missing_bans))

    for instrument_id in sorted(open_ids):
        item = tracker_by_id.get(instrument_id)
        if not item:
            continue
        for key in ["name_zh", "priority", "recording_need", "status"]:
            if not str(item.get(key, "")).strip():
                failures.append(f"{instrument_id}: procurement field {key} is required")
        if item.get("status") not in VALID_STATUSES:
            failures.append(f"{instrument_id}: invalid procurement status {item.get('status')}")
        if item.get("status") == "approved":
            failures.append(f"{instrument_id}: tracker says approved but manifest is not approved")

        checklist_item = checklist_by_id.get(instrument_id)
        if checklist_item:
            for key in ["name_zh", "priority", "status", "required_files", "takes"]:
                if key not in checklist_item:
                    failures.append(f"{instrument_id}: checklist field {key} is required")
            if checklist_item.get("status") == "imported_approved":
                failures.append(f"{instrument_id}: checklist says imported_approved but manifest is not approved")
            if checklist_item.get("status") not in {
                "not_requested",
                "requested",
                "received_pending_review",
                "imported_approved",
            }:
                failures.append(f"{instrument_id}: invalid checklist status {checklist_item.get('status')}")

    print(
        f"Audio procurement tracker: {len(open_ids)} open instrument(s), "
        f"{len(approved_ids)} approved, {len(checklist_items)} checklist item(s)."
    )

    if failures:
        print("\nAudio procurement tracker check failed:")
        for failure in failures:
            print(f"- {failure}")
        raise SystemExit(1)

    print("Audio procurement tracker check passed.")


if __name__ == "__main__":
    main()
