#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCORECARD_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "professional_listening_review_scorecard.json"
)
PACK_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "full_open_recording_delivery_pack.json"
)
INBOX_MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "recording_inbox_manifest.json"
)
DOC_PATH = ROOT / "Docs" / "AssetLicenses" / "ProfessionalListeningReview.zh-Hant.md"

REQUIRED_CRITERIA = {
    "instrument_identity",
    "professional_timbre",
    "technique_representation",
    "noise_and_recording_quality",
    "app_training_fit",
}
REQUIRED_HIGH_RISK_IDS = {"erhu", "gaohu", "zhonghu", "banhu", "gehu", "suona", "sheng"}
REQUIRED_DOC_TOKENS = [
    "professional_listening_review_scorecard.json",
    "approved_for_import",
    "import_recording_inbox_batch.py",
    "import_verified_audio.py --approve",
    "Suno",
    "VST",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def has_placeholder(value):
    if isinstance(value, str):
        return "TO_BE_FILLED" in value
    if isinstance(value, dict):
        return any(has_placeholder(item) for item in value.values())
    if isinstance(value, list):
        return any(has_placeholder(item) for item in value)
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    failures = []
    warnings = []

    scorecard = load_json(SCORECARD_PATH)
    pack = load_json(PACK_PATH)
    inbox_manifest = load_json(INBOX_MANIFEST_PATH)

    required_ids = set(pack.get("required_instrument_ids", []))
    applies_to = set(scorecard.get("applies_to_open_instrument_ids", []))
    if applies_to != required_ids:
        failures.append(
            "applies_to_open_instrument_ids mismatch: "
            + f"got {sorted(applies_to)}, expected {sorted(required_ids)}"
        )
    reverify_ids = set(scorecard.get("applies_to_reverify_instrument_ids", []))
    expected_reverify_ids = set(inbox_manifest.get("phase_1_reverify_instrument_ids", []))
    if reverify_ids != expected_reverify_ids:
        failures.append(
            "applies_to_reverify_instrument_ids mismatch: "
            + f"got {sorted(reverify_ids)}, expected {sorted(expected_reverify_ids)}"
        )
    reviewable_ids = required_ids | reverify_ids

    reviewer_requirements = scorecard.get("reviewer_requirements") or {}
    if int(reviewer_requirements.get("minimum_reviewers", 0)) < 1:
        failures.append("reviewer_requirements.minimum_reviewers must be at least 1")
    if "performer" not in str(reviewer_requirements.get("conflict_rule", "")).lower():
        failures.append("reviewer_requirements.conflict_rule must mention performer conflict")

    score_scale = scorecard.get("score_scale") or {}
    if int(score_scale.get("min", 0)) != 1 or int(score_scale.get("max", 0)) != 5:
        failures.append("score_scale must be 1-5")
    minimum_score = float(score_scale.get("passing_minimum_per_criterion", 0))
    passing_average = float(score_scale.get("passing_average", 0))
    if minimum_score < 4:
        failures.append("score_scale.passing_minimum_per_criterion must be at least 4")
    if passing_average < 4.25:
        failures.append("score_scale.passing_average must be at least 4.25")

    criteria_by_id = {item.get("id"): item for item in scorecard.get("criteria", [])}
    if set(criteria_by_id) != REQUIRED_CRITERIA:
        failures.append(
            "criteria mismatch: "
            + f"got {sorted(criteria_by_id)}, expected {sorted(REQUIRED_CRITERIA)}"
        )
    for criterion_id, item in criteria_by_id.items():
        if not str(item.get("label_zh", "")).strip():
            failures.append(f"{criterion_id}: label_zh is required")
        if not str(item.get("description", "")).strip():
            failures.append(f"{criterion_id}: description is required")

    high_risk_by_id = {
        item.get("instrument_id"): item
        for item in scorecard.get("high_risk_differentiation_checks", [])
    }
    if set(high_risk_by_id) != REQUIRED_HIGH_RISK_IDS:
        failures.append(
            "high_risk_differentiation_checks mismatch: "
            + f"got {sorted(high_risk_by_id)}, expected {sorted(REQUIRED_HIGH_RISK_IDS)}"
        )
    for instrument_id, item in high_risk_by_id.items():
        if not isinstance(item.get("must_distinguish_from"), list) or len(item["must_distinguish_from"]) < 2:
            failures.append(f"{instrument_id}: must_distinguish_from must include at least two entries")
        if not str(item.get("notes", "")).strip():
            failures.append(f"{instrument_id}: notes are required")

    if not DOC_PATH.exists():
        failures.append("Missing ProfessionalListeningReview.zh-Hant.md")
    else:
        doc_text = DOC_PATH.read_text(encoding="utf-8")
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"ProfessionalListeningReview.zh-Hant.md missing token: {token}")

    allowed_decisions = set(inbox_manifest.get("strict_mode_review_decisions_allowed", []))
    if allowed_decisions != {"approved_for_import"}:
        failures.append("recording inbox strict_mode_review_decisions_allowed must be approved_for_import")

    approved_ids = set()
    review_records = scorecard.get("review_records", [])
    if not isinstance(review_records, list):
        failures.append("review_records must be a list")
        review_records = []

    for record in review_records:
        instrument_id = record.get("instrument_id")
        if instrument_id not in reviewable_ids:
            failures.append(f"review record has unknown instrument_id: {instrument_id}")
            continue
        if has_placeholder(record):
            failures.append(f"{instrument_id}: review record still contains TO_BE_FILLED placeholder")

        reviewer = record.get("reviewer") or {}
        for key in ["name", "role", "organization"]:
            if not str(reviewer.get(key, "")).strip():
                failures.append(f"{instrument_id}: reviewer.{key} is required")
        if not str(record.get("reviewed_at", "")).strip():
            failures.append(f"{instrument_id}: reviewed_at is required")

        scores = record.get("scores") or {}
        values = []
        for criterion_id in sorted(REQUIRED_CRITERIA):
            if criterion_id not in scores:
                failures.append(f"{instrument_id}: missing score {criterion_id}")
                continue
            try:
                score = float(scores[criterion_id])
            except (TypeError, ValueError):
                failures.append(f"{instrument_id}: score {criterion_id} must be numeric")
                continue
            if score < 1 or score > 5:
                failures.append(f"{instrument_id}: score {criterion_id} outside 1-5")
            if score < minimum_score:
                failures.append(f"{instrument_id}: score {criterion_id} below {minimum_score:g}")
            values.append(score)

        if values:
            average = sum(values) / len(values)
            if average < passing_average:
                failures.append(f"{instrument_id}: average score below {passing_average:g}")
            if record.get("average_score") is not None:
                try:
                    if abs(float(record["average_score"]) - average) > 0.02:
                        failures.append(f"{instrument_id}: average_score does not match scores")
                except (TypeError, ValueError):
                    failures.append(f"{instrument_id}: average_score must be numeric")

        if record.get("decision") == "approved_for_import" and not any(
            failure.startswith(f"{instrument_id}:") for failure in failures
        ):
            approved_ids.add(instrument_id)

    missing_approved = sorted(reviewable_ids - approved_ids)
    if missing_approved:
        message = (
            "No approved professional listening review for open/reverify recordings: "
            + ", ".join(missing_approved[:10])
            + (" ..." if len(missing_approved) > 10 else "")
        )
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    print(
        f"Professional listening scorecard: {len(criteria_by_id)}/{len(REQUIRED_CRITERIA)} criteria, "
        f"{len(approved_ids)}/{len(reviewable_ids)} approved open/reverify instrument(s)."
    )
    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nProfessional listening scorecard check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Professional listening scorecard check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
