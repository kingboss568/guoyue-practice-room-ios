#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "manifests"
    / "verified_audio_sources.json"
)
PACK_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "full_open_recording_delivery_pack.json"
)
TRACKER_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "audio_procurement_tracker.json"
)
CHECKLIST_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "recording_delivery_checklist.json"
)

REQUIRED_CONFIRMATIONS = {
    "real_instrument_recording",
    "commercial_app_distribution",
    "derivative_processing_allowed",
    "global_perpetual_use",
    "not_ai_generated",
    "not_vst_or_sample_library",
    "not_ripped_from_streaming_or_video",
}


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def contains_placeholder(value):
    if isinstance(value, str):
        return "TO_BE_FILLED" in value
    if isinstance(value, dict):
        return any(contains_placeholder(v) for v in value.values())
    if isinstance(value, list):
        return any(contains_placeholder(v) for v in value)
    return False


def main() -> int:
    failures = []

    manifest = load_json(MANIFEST_PATH)
    pack = load_json(PACK_PATH)
    tracker = load_json(TRACKER_PATH)
    checklist = load_json(CHECKLIST_PATH)

    open_ids = list(manifest.get("open_instrument_ids", []))
    required_ids = set(open_ids)
    pack_ids = set(pack.get("required_instrument_ids", []))
    if pack_ids != required_ids:
        failures.append(
            "full recording pack required_instrument_ids mismatch: "
            + f"got {sorted(pack_ids)} expected {sorted(required_ids)}"
        )

    approved_ids = {
        item.get("instrument_id")
        for item in manifest.get("approved", [])
        if item.get("status") == "approved"
    }
    accidental_approved = sorted(pack_ids & approved_ids)
    if accidental_approved:
        failures.append(
            "full recording pack must not include already approved instruments: "
            + ", ".join(accidental_approved)
        )

    rules = pack.get("global_delivery_rules", {})
    confirmations = set(rules.get("required_release_confirmations", []))
    if confirmations != REQUIRED_CONFIRMATIONS:
        failures.append("full recording pack required_release_confirmations are incomplete")
    if int(rules.get("minimum_takes_per_instrument", 0)) < 3:
        failures.append("full recording pack minimum_takes_per_instrument must be at least 3")
    if int(rules.get("minimum_clean_duration_seconds", 0)) < 6:
        failures.append("full recording pack minimum_clean_duration_seconds must be at least 6")
    if "copyrighted melodies" not in str(rules.get("composition_rights", "")):
        failures.append("full recording pack must warn against copyrighted melodies")
    if "professional" not in str(rules.get("professional_review_gate", "")).lower():
        failures.append("full recording pack must require professional listening review")

    tracker_by_id = {item.get("instrument_id"): item for item in tracker.get("items", [])}
    checklist_by_id = {item.get("instrument_id"): item for item in checklist.get("items", [])}
    items_by_id = {item.get("instrument_id"): item for item in pack.get("items", [])}

    missing_items = sorted(required_ids - set(items_by_id))
    if missing_items:
        failures.append("full recording pack missing items: " + ", ".join(missing_items))

    extra_items = sorted(set(items_by_id) - required_ids)
    if extra_items:
        failures.append("full recording pack has non-open instruments: " + ", ".join(extra_items))

    for instrument_id in open_ids:
        item = items_by_id.get(instrument_id)
        if not item:
            continue

        tracker_item = tracker_by_id.get(instrument_id)
        checklist_item = checklist_by_id.get(instrument_id)
        if not tracker_item:
            failures.append(f"{instrument_id}: procurement tracker item is missing")
        if not checklist_item:
            failures.append(f"{instrument_id}: delivery checklist item is missing")
        if tracker_item and item.get("name_zh") != tracker_item.get("name_zh"):
            failures.append(f"{instrument_id}: name_zh does not match procurement tracker")
        if checklist_item and item.get("priority") != checklist_item.get("priority"):
            failures.append(f"{instrument_id}: priority does not match delivery checklist")
        if tracker_item and item.get("procurement_priority") != tracker_item.get("priority"):
            failures.append(f"{instrument_id}: procurement_priority does not match tracker")
        if checklist_item and checklist_item.get("status") == "imported_approved":
            failures.append(f"{instrument_id}: checklist says imported_approved but manifest is open")

        release_template = item.get("release_template", "")
        release_path = ROOT / release_template
        if not release_template or not release_path.exists():
            failures.append(f"{instrument_id}: release_template missing: {release_template}")
        else:
            release = load_json(release_path)
            if release.get("instrument_id") != instrument_id:
                failures.append(f"{instrument_id}: release template instrument_id mismatch")
            if release.get("template_only") is not True:
                failures.append(f"{instrument_id}: release template must have template_only=true")
            if not contains_placeholder(release):
                failures.append(f"{instrument_id}: release template must include TO_BE_FILLED placeholders")
            for key in REQUIRED_CONFIRMATIONS:
                if release.get("confirmations", {}).get(key) is not True:
                    failures.append(f"{instrument_id}: release template confirmation {key} must be true")

        delivery_folder = str(item.get("delivery_folder", ""))
        expected_folder = f"Design/Source/VerifiedAudio/inbox/full/{instrument_id}/"
        if delivery_folder != expected_folder:
            failures.append(f"{instrument_id}: delivery_folder must be {expected_folder}")

        takes = item.get("take_specs", [])
        if len(takes) < 3:
            failures.append(f"{instrument_id}: at least 3 take_specs are required")
        filenames = set()
        for take in takes:
            filename = str(take.get("filename", ""))
            if not filename.startswith(f"{instrument_id}_take"):
                failures.append(f"{instrument_id}: take filename must start with {instrument_id}_take: {filename}")
            if not filename.lower().endswith((".wav", ".aiff", ".aif")):
                failures.append(f"{instrument_id}: take filename must be wav/aiff/aif: {filename}")
            if filename in filenames:
                failures.append(f"{instrument_id}: duplicate take filename: {filename}")
            filenames.add(filename)
            if int(take.get("minimum_clean_seconds", 0)) < 6:
                failures.append(f"{instrument_id}: take {filename} minimum_clean_seconds must be at least 6")
            if not str(take.get("content", "")).strip():
                failures.append(f"{instrument_id}: take {filename} content is required")

        reject_if = item.get("reject_if", [])
        if len(reject_if) < 3:
            failures.append(f"{instrument_id}: reject_if must list at least 3 rejection checks")

    print(f"Full open recording delivery pack: {len(items_by_id)}/{len(required_ids)} open instrument(s)")

    if failures:
        print("\nFull open recording delivery pack check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Full open recording delivery pack check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
