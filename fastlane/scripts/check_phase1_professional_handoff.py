#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HANDOFF = ROOT / "Design" / "Review" / "Phase1ProfessionalHandoff" / "phase1_professional_handoff_manifest.json"
DOC = ROOT / "Docs" / "Phase1ProfessionalHandoff.zh-Hant.md"
PRIORITY_PACK = ROOT / "Design" / "Source" / "VerifiedAudio" / "procurement" / "priority1_recording_delivery_pack.json"
VISUAL_CARDS = ROOT / "Design" / "Source" / "InstrumentReferenceAudit" / "professional_visual_review_cards.json"
CANDIDATE_MANIFEST = ROOT / "Design" / "Review" / "ArtworkCandidates" / "candidate_manifest.json"

REQUIRED_IDS = ["erhu", "gaohu", "zhonghu", "gehu", "sheng", "suona", "banhu"]
REVERIFY_IDS = {"sheng"}

REQUIRED_DOC_TOKENS = [
    "第一批 7 件",
    "Design/Source/VerifiedAudio/inbox/full/<instrument_id>/",
    "Design/Source/VerifiedAudio/inbox/reverify/sheng/",
    "Suno",
    "AI-generated instrument tone",
    "VST",
    "sample library",
    "professional_visual_review_cards.json",
    "approval_drafts",
    "import_verified_audio.py",
    "import_approved_artwork.py",
    "iPhone 6.9",
    "iPad 13",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def nonempty_list(value, minimum):
    return isinstance(value, list) and len([item for item in value if str(item).strip()]) >= minimum


def main() -> int:
    failures = []

    handoff = load_json(HANDOFF)
    priority_pack = load_json(PRIORITY_PACK)
    visual_cards = load_json(VISUAL_CARDS)
    candidate_manifest = load_json(CANDIDATE_MANIFEST)
    doc_text = DOC.read_text(encoding="utf-8") if DOC.exists() else ""

    if handoff.get("status") != "handoff_ready_for_external_professional_review":
        failures.append("phase1 handoff status must be handoff_ready_for_external_professional_review")
    if "not approval evidence" not in str(handoff.get("policy", "")):
        failures.append("phase1 handoff policy must state it is not approval evidence")
    if handoff.get("required_instrument_ids") != REQUIRED_IDS:
        failures.append("phase1 handoff required_instrument_ids must preserve the priority order")

    shared_files = handoff.get("shared_files", {})
    for key, rel_path in shared_files.items():
        if not str(rel_path).strip():
            failures.append(f"shared_files.{key} is required")
            continue
        if not (ROOT / rel_path).exists():
            failures.append(f"shared file missing for {key}: {rel_path}")

    for key in ["global_recording_rules", "global_artwork_rules", "required_next_steps_before_app_asset_import"]:
        if not nonempty_list(handoff.get(key), 5):
            failures.append(f"{key} must include at least five entries")

    priority_by_id = {item.get("instrument_id"): item for item in priority_pack.get("items", [])}
    visual_by_id = {item.get("instrument_id"): item for item in visual_cards.get("cards", [])}
    candidate_by_id = {item.get("instrument_id"): item for item in candidate_manifest.get("items", [])}
    handoff_by_id = {item.get("instrument_id"): item for item in handoff.get("items", [])}

    if set(handoff_by_id) != set(REQUIRED_IDS):
        failures.append("phase1 handoff items must exactly match required instruments")

    for instrument_id in REQUIRED_IDS:
        item = handoff_by_id.get(instrument_id)
        priority_item = priority_by_id.get(instrument_id)
        visual_item = visual_by_id.get(instrument_id)
        candidate_item = candidate_by_id.get(instrument_id)
        if not item or not priority_item or not visual_item or not candidate_item:
            failures.append(f"{instrument_id}: handoff, priority pack, visual card, and candidate manifest entries are required")
            continue

        if item.get("release_template") != priority_item.get("release_template"):
            failures.append(f"{instrument_id}: release_template must match priority pack")
        if not (ROOT / item.get("release_template", "")).exists():
            failures.append(f"{instrument_id}: release_template file missing")

        expected_folder = (
            f"Design/Source/VerifiedAudio/inbox/reverify/{instrument_id}/"
            if instrument_id in REVERIFY_IDS
            else f"Design/Source/VerifiedAudio/inbox/full/{instrument_id}/"
        )
        if item.get("recording_delivery_folder") != expected_folder:
            failures.append(f"{instrument_id}: recording_delivery_folder must be {expected_folder}")
        if item.get("recording_delivery_folder") != priority_item.get("delivery_folder"):
            failures.append(f"{instrument_id}: recording_delivery_folder must match priority pack")

        expected_scope = "approved_source_reverify_or_new_recording" if instrument_id in REVERIFY_IDS else "full_new_recording_required"
        if item.get("recording_scope") != expected_scope:
            failures.append(f"{instrument_id}: recording_scope must be {expected_scope}")

        take_filenames = [take.get("filename") for take in priority_item.get("take_specs", [])]
        if item.get("required_recording_takes") != take_filenames:
            failures.append(f"{instrument_id}: required_recording_takes must match priority pack")
        if not nonempty_list(item.get("recording_review_focus"), 3):
            failures.append(f"{instrument_id}: recording_review_focus must include at least three entries")

        if item.get("artwork_candidate") != visual_item.get("candidate_path"):
            failures.append(f"{instrument_id}: artwork_candidate must match visual review card")
        if item.get("artwork_candidate") != candidate_item.get("path"):
            failures.append(f"{instrument_id}: artwork_candidate must match candidate manifest")
        if not (ROOT / item.get("artwork_candidate", "")).exists():
            failures.append(f"{instrument_id}: artwork candidate file missing")

        expected_draft = f"Design/Review/ArtworkCandidates/approval_drafts/{instrument_id}.approval.draft.json"
        if item.get("artwork_approval_draft") != expected_draft:
            failures.append(f"{instrument_id}: artwork_approval_draft must be {expected_draft}")
        if not (ROOT / expected_draft).exists():
            failures.append(f"{instrument_id}: artwork approval draft missing")
        if not nonempty_list(item.get("visual_review_focus"), 3):
            failures.append(f"{instrument_id}: visual_review_focus must include at least three entries")

    if not DOC.exists():
        failures.append("Missing Phase1ProfessionalHandoff.zh-Hant.md")
    else:
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"Phase1ProfessionalHandoff.zh-Hant.md missing token: {token}")

    print(f"Phase-1 professional handoff: {len(handoff_by_id)}/{len(REQUIRED_IDS)} instrument(s)")

    if failures:
        print("\nPhase-1 professional handoff check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Phase-1 professional handoff check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
