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
WORK_ORDER_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "performer_recording_work_order.json"
)
SCORECARD_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "professional_listening_review_scorecard.json"
)
DOC_PATH = ROOT / "Docs" / "AssetLicenses" / "PerformerRecordingWorkOrder.zh-Hant.md"

PHASE_1_OPEN_IDS = {"zhonghu", "gehu"}
HIGH_RISK_DIFFERENTIATION_IDS = {
    "erhu",
    "gaohu",
    "zhonghu",
    "banhu",
    "gehu",
    "suona",
    "sheng",
}
REQUIRED_REQUIREMENT_FLAGS = {
    "must_be_primary_orchestra_performer",
    "must_record_real_instrument",
    "must_identify_instrument_make_or_type",
    "must_confirm_no_ai_no_vst_no_sample_library",
    "must_confirm_no_streaming_or_video_extraction",
    "must_confirm_original_or_public_domain_gestures_only",
}
REQUIRED_CRITERIA = {
    "instrument_identity",
    "professional_timbre",
    "technique_representation",
    "noise_and_recording_quality",
    "app_training_fit",
}
REQUIRED_DOC_TOKENS = [
    "二胡",
    "高胡",
    "中胡",
    "革胡",
    "嗩吶",
    "板胡",
    "7 件外部參考缺口",
    "Design/Source/VerifiedAudio/inbox/reverify/<instrument_id>/",
    "import_verified_audio.py --approve",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    failures = []

    manifest = load_json(MANIFEST_PATH)
    pack = load_json(PACK_PATH)
    work_order = load_json(WORK_ORDER_PATH)
    scorecard = load_json(SCORECARD_PATH)
    doc_text = DOC_PATH.read_text(encoding="utf-8") if DOC_PATH.exists() else ""

    open_ids = set(manifest.get("open_instrument_ids", []))
    pack_ids = set(pack.get("required_instrument_ids", []))
    if pack_ids != open_ids:
        failures.append("recording pack required ids must match manifest open ids")

    phase_1 = set(work_order.get("phase_1_required_instrument_ids", []))
    if phase_1 != PHASE_1_OPEN_IDS:
        failures.append(
            "phase_1_required_instrument_ids must be high-risk open instruments: "
            + ", ".join(sorted(PHASE_1_OPEN_IDS))
        )
    approved_ids = {
        item.get("instrument_id")
        for item in manifest.get("approved", [])
        if item.get("status") == "approved"
    }
    reverify_ids = set(work_order.get("phase_1_reverify_instrument_ids", []))
    unknown_reverify_ids = sorted(reverify_ids - approved_ids)
    if unknown_reverify_ids:
        failures.append(
            "phase_1_reverify_instrument_ids contains non-approved instruments: "
            + ", ".join(unknown_reverify_ids)
        )

    phase_2 = set(work_order.get("phase_2_required_instrument_ids", []))
    phase_3 = set(work_order.get("phase_3_required_instrument_ids", []))
    all_phase_open = phase_1 | phase_2 | phase_3
    if all_phase_open != open_ids:
        failures.append(
            "work order phases must cover every open instrument exactly once: "
            + f"got {len(all_phase_open)} expected {len(open_ids)}"
        )
    if (phase_1 & phase_2) or (phase_1 & phase_3) or (phase_2 & phase_3):
        failures.append("work order phases must not overlap")

    if work_order.get("source_pack") != "Design/Source/VerifiedAudio/procurement/full_open_recording_delivery_pack.json":
        failures.append("work order must point to full_open_recording_delivery_pack.json")
    if work_order.get("delivery_root") != "Design/Source/VerifiedAudio/inbox/full/":
        failures.append("work order delivery_root is incorrect")
    if work_order.get("reverify_root") != "Design/Source/VerifiedAudio/inbox/reverify/":
        failures.append("work order reverify_root is incorrect")

    performer_requirements = work_order.get("performer_requirements", {})
    for flag in REQUIRED_REQUIREMENT_FLAGS:
        if performer_requirements.get(flag) is not True:
            failures.append(f"performer requirement must be true: {flag}")

    hard_rejects = " ".join(work_order.get("hard_reject_conditions", [])).lower()
    for token in ["ai", "vst", "sample library", "youtube", "streaming", "clipped"]:
        if token not in hard_rejects:
            failures.append(f"hard reject conditions must mention {token}")

    scorecard_ids = set(scorecard.get("applies_to_open_instrument_ids", []))
    if scorecard_ids != open_ids:
        failures.append("scorecard applies_to_open_instrument_ids must match manifest open ids")

    scale = scorecard.get("score_scale", {})
    if int(scale.get("passing_minimum_per_criterion", 0)) < 4:
        failures.append("scorecard passing_minimum_per_criterion must be at least 4")
    if float(scale.get("passing_average", 0)) < 4.25:
        failures.append("scorecard passing_average must be at least 4.25")
    if int(scorecard.get("reviewer_requirements", {}).get("minimum_reviewers", 0)) < 1:
        failures.append("scorecard minimum_reviewers must be at least 1")

    criteria_ids = {item.get("id") for item in scorecard.get("criteria", [])}
    missing_criteria = sorted(REQUIRED_CRITERIA - criteria_ids)
    if missing_criteria:
        failures.append("scorecard missing criteria: " + ", ".join(missing_criteria))

    differentiation_ids = {
        item.get("instrument_id")
        for item in scorecard.get("high_risk_differentiation_checks", [])
    }
    expected_differentiation = HIGH_RISK_DIFFERENTIATION_IDS
    if differentiation_ids != expected_differentiation:
        failures.append(
            "scorecard high-risk differentiation checks must cover: "
            + ", ".join(sorted(expected_differentiation))
        )

    if not DOC_PATH.exists():
        failures.append("Missing PerformerRecordingWorkOrder.zh-Hant.md")
    else:
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"PerformerRecordingWorkOrder.zh-Hant.md missing token: {token}")

    print(
        "Recording work order: "
        + f"{len(all_phase_open)}/{len(open_ids)} open instrument(s), "
        + f"{len(differentiation_ids)} high-risk listening check(s)."
    )

    if failures:
        print("\nRecording work order check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Recording work order check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
