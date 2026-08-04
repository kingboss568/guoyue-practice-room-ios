#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PACK_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "priority1_recording_delivery_pack.json"
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
REQUEST_DOC_PATH = ROOT / "Docs" / "AssetLicenses" / "Phase1PerformerRequest.zh-Hant.md"

REQUIRED_IDS = {"erhu", "gaohu", "zhonghu", "gehu", "sheng", "suona", "banhu"}
REVERIFY_IDS = {"sheng"}
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

    pack = load_json(PACK_PATH)
    tracker = load_json(TRACKER_PATH)
    checklist = load_json(CHECKLIST_PATH)
    request_doc = REQUEST_DOC_PATH.read_text(encoding="utf-8") if REQUEST_DOC_PATH.exists() else ""

    if not REQUEST_DOC_PATH.exists():
        failures.append("Missing Phase1PerformerRequest.zh-Hant.md")
    else:
        for token in [
            "二胡",
            "高胡",
            "中胡",
            "革胡",
            "嗩吶",
            "板胡",
            "Design/Source/VerifiedAudio/inbox/full/<instrument_id>/",
            "Design/Source/VerifiedAudio/inbox/reverify/sheng/",
            "Suno",
            "AI-generated instrument tone",
            "VST",
            "sample library",
        ]:
            if token not in request_doc:
                failures.append(f"Phase1PerformerRequest.zh-Hant.md missing token: {token}")

    pack_ids = set(pack.get("required_instrument_ids", []))
    if pack_ids != REQUIRED_IDS:
        failures.append(
            "priority1 required_instrument_ids mismatch: "
            + f"got {sorted(pack_ids)} expected {sorted(REQUIRED_IDS)}"
        )

    rules = pack.get("global_delivery_rules", {})
    confirmations = set(rules.get("required_release_confirmations", []))
    if confirmations != REQUIRED_CONFIRMATIONS:
        failures.append("priority1 required_release_confirmations are incomplete")
    if int(rules.get("minimum_takes_per_instrument", 0)) < 3:
        failures.append("priority1 minimum_takes_per_instrument must be at least 3")
    if int(rules.get("minimum_clean_duration_seconds", 0)) < 6:
        failures.append("priority1 minimum_clean_duration_seconds must be at least 6")

    tracker_by_id = {item.get("instrument_id"): item for item in tracker.get("items", [])}
    checklist_by_id = {item.get("instrument_id"): item for item in checklist.get("items", [])}
    items_by_id = {item.get("instrument_id"): item for item in pack.get("items", [])}

    missing_items = sorted(REQUIRED_IDS - set(items_by_id))
    if missing_items:
        failures.append("priority1 pack missing items: " + ", ".join(missing_items))

    for instrument_id in sorted(REQUIRED_IDS):
        item = items_by_id.get(instrument_id)
        if not item:
            continue

        tracker_item = tracker_by_id.get(instrument_id)
        checklist_item = checklist_by_id.get(instrument_id)
        if not tracker_item or tracker_item.get("priority") != "critical":
            failures.append(f"{instrument_id}: procurement tracker priority must be critical")
        if not checklist_item or checklist_item.get("priority") != 1:
            failures.append(f"{instrument_id}: delivery checklist priority must be 1")

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
        if instrument_id in REVERIFY_IDS:
            expected_folder = f"Design/Source/VerifiedAudio/inbox/reverify/{instrument_id}/"
        else:
            expected_folder = f"Design/Source/VerifiedAudio/inbox/full/{instrument_id}/"
        if delivery_folder != expected_folder:
            failures.append(f"{instrument_id}: delivery_folder must be {expected_folder}")

        takes = item.get("take_specs", [])
        if len(takes) < 3:
            failures.append(f"{instrument_id}: at least 3 take_specs are required")
        filenames = set()
        for take in takes:
            filename = take.get("filename", "")
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

    print(f"Priority-1 recording delivery pack: {len(items_by_id)}/{len(REQUIRED_IDS)} instrument(s)")

    if failures:
        print("\nPriority-1 recording delivery pack check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Priority-1 recording delivery pack check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
