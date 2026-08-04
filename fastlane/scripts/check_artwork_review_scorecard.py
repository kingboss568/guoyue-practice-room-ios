#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_IDS = {"gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"}
REQUIRED_CRITERIA = {
    "instrument_identity",
    "morphology_accuracy",
    "differentiation_from_neighbors",
    "thumbnail_legibility",
    "no_fantasy_details",
    "app_store_fit",
}
SCORECARD_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "high_risk_artwork_review_scorecard.json"
)
MORPHOLOGY_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "high_risk_artwork_morphology_specs.json"
)
CANDIDATE_MANIFEST_PATH = ROOT / "Design" / "Review" / "ArtworkCandidates" / "candidate_manifest.json"
APPROVAL_DRAFT_ROOT = ROOT / "Design" / "Review" / "ArtworkCandidates" / "approval_drafts"
REVIEW_DOC_PATH = ROOT / "Docs" / "InstrumentArtworkProfessionalReview.zh-Hant.md"


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


def nonempty_list(value, minimum=1):
    return isinstance(value, list) and len([item for item in value if str(item).strip()]) >= minimum


def review_record_is_approved(record, criteria_ids, policy, failures):
    instrument_id = record.get("instrument_id")
    if instrument_id not in REQUIRED_IDS:
        failures.append(f"review record has unknown instrument_id: {instrument_id}")
        return False

    if has_placeholder(record):
        failures.append(f"{instrument_id}: review record still contains TO_BE_FILLED placeholder")
        return False

    reviewer = record.get("reviewer") or {}
    for key in ["name", "role", "organization"]:
        if not str(reviewer.get(key, "")).strip():
            failures.append(f"{instrument_id}: review record reviewer.{key} is required")

    if not str(record.get("reviewed_at", "")).strip():
        failures.append(f"{instrument_id}: review record reviewed_at is required")

    scores = record.get("scores") or {}
    min_score = float(policy.get("minimum_score_per_criterion", 4))
    values = []
    for criterion_id in sorted(criteria_ids):
        if criterion_id not in scores:
            failures.append(f"{instrument_id}: missing score for {criterion_id}")
            continue
        try:
            score = float(scores[criterion_id])
        except (TypeError, ValueError):
            failures.append(f"{instrument_id}: score for {criterion_id} must be numeric")
            continue
        if score < min_score:
            failures.append(f"{instrument_id}: score for {criterion_id} below {min_score:g}")
        if score < 1 or score > 5:
            failures.append(f"{instrument_id}: score for {criterion_id} outside 1-5 scale")
        values.append(score)

    min_average = float(policy.get("minimum_average_score", 4.25))
    if values:
        average = sum(values) / len(values)
        declared_average = record.get("average_score")
        if declared_average is not None:
            try:
                if abs(float(declared_average) - average) > 0.02:
                    failures.append(f"{instrument_id}: average_score does not match score average")
            except (TypeError, ValueError):
                failures.append(f"{instrument_id}: average_score must be numeric")
        if average < min_average:
            failures.append(f"{instrument_id}: average score below {min_average:g}")

    if record.get("decision") != "approved":
        failures.append(f"{instrument_id}: review record decision must be approved")

    if not str(record.get("approval_json", "")).strip():
        failures.append(f"{instrument_id}: review record approval_json path is required")

    return not any(failure.startswith(f"{instrument_id}:") for failure in failures)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    failures = []
    warnings = []

    scorecard = load_json(SCORECARD_PATH)
    morphology = load_json(MORPHOLOGY_PATH)
    candidate_manifest = load_json(CANDIDATE_MANIFEST_PATH)

    scorecard_ids = set(scorecard.get("applies_to_high_risk_instrument_ids", []))
    if scorecard_ids != REQUIRED_IDS:
        failures.append(
            "applies_to_high_risk_instrument_ids mismatch: "
            + f"got {sorted(scorecard_ids)}, expected {sorted(REQUIRED_IDS)}"
        )

    policy = scorecard.get("score_policy") or {}
    if policy.get("final_import_tool") != "python3 fastlane/scripts/import_approved_artwork.py --approve":
        failures.append("score_policy.final_import_tool must require import_approved_artwork.py --approve")
    if policy.get("approval_requires_import_tool") is not True:
        failures.append("score_policy.approval_requires_import_tool must be true")
    if float(policy.get("minimum_score_per_criterion", 0)) < 4:
        failures.append("score_policy.minimum_score_per_criterion must be at least 4")
    if float(policy.get("minimum_average_score", 0)) < 4.25:
        failures.append("score_policy.minimum_average_score must be at least 4.25")
    if int(policy.get("minimum_professional_reviewers_for_import", 0)) < 1:
        failures.append("score_policy.minimum_professional_reviewers_for_import must be at least 1")

    criteria = scorecard.get("shared_criteria", [])
    criteria_by_id = {item.get("criterion_id"): item for item in criteria}
    if set(criteria_by_id) != REQUIRED_CRITERIA:
        failures.append(
            "shared_criteria mismatch: "
            + f"got {sorted(criteria_by_id)}, expected {sorted(REQUIRED_CRITERIA)}"
        )
    for criterion_id, item in criteria_by_id.items():
        if float(item.get("required_minimum_score", 0)) < 4:
            failures.append(f"{criterion_id}: required_minimum_score must be at least 4")
        if not str(item.get("description", "")).strip():
            failures.append(f"{criterion_id}: description is required")

    spec_by_id = {item.get("instrument_id"): item for item in morphology.get("specs", [])}
    candidate_by_id = {item.get("instrument_id"): item for item in candidate_manifest.get("items", [])}

    matrix_by_id = {item.get("instrument_id"): item for item in scorecard.get("differentiation_matrix", [])}
    reviews_by_id = {item.get("instrument_id"): item for item in scorecard.get("per_instrument_reviews", [])}
    for label, lookup in [
        ("differentiation_matrix", matrix_by_id),
        ("per_instrument_reviews", reviews_by_id),
    ]:
        missing = sorted(REQUIRED_IDS - set(lookup))
        unknown = sorted(set(lookup) - REQUIRED_IDS)
        if missing:
            failures.append(f"{label} missing: " + ", ".join(missing))
        if unknown:
            failures.append(f"{label} has unknown ids: " + ", ".join(unknown))

    for instrument_id in sorted(REQUIRED_IDS):
        spec = spec_by_id.get(instrument_id)
        candidate = candidate_by_id.get(instrument_id)
        matrix = matrix_by_id.get(instrument_id)
        review = reviews_by_id.get(instrument_id)
        if not spec or not candidate or not matrix or not review:
            failures.append(f"{instrument_id}: missing spec, candidate, matrix, or review entry")
            continue

        draft_path = APPROVAL_DRAFT_ROOT / f"{instrument_id}.approval.draft.json"
        if not draft_path.exists():
            failures.append(f"{instrument_id}: approval draft is missing")

        if review.get("candidate_path") != candidate.get("path"):
            failures.append(f"{instrument_id}: candidate_path must match candidate manifest")
        if review.get("morphology_spec_id") != instrument_id:
            failures.append(f"{instrument_id}: morphology_spec_id must match instrument_id")
        expected_draft = f"Design/Review/ArtworkCandidates/approval_drafts/{instrument_id}.approval.draft.json"
        if review.get("approval_draft_path") != expected_draft:
            failures.append(f"{instrument_id}: approval_draft_path must match {expected_draft}")
        if int(review.get("required_reference_count", 0)) < 2:
            failures.append(f"{instrument_id}: required_reference_count must be at least 2")

        if set(review.get("must_validate", [])) != set(spec.get("must_show", [])):
            failures.append(f"{instrument_id}: must_validate must match morphology spec must_show")
        if set(review.get("reject_if", [])) != set(spec.get("must_not_show", [])):
            failures.append(f"{instrument_id}: reject_if must match morphology spec must_not_show")
        if not nonempty_list(review.get("differentiation_targets"), 3):
            failures.append(f"{instrument_id}: differentiation_targets must include similar instruments")
        if not nonempty_list(matrix.get("must_distinguish_from"), 3):
            failures.append(f"{instrument_id}: matrix must_distinguish_from must include similar instruments")
        if not nonempty_list(matrix.get("reject_if_confused_with"), 2):
            failures.append(f"{instrument_id}: matrix reject_if_confused_with must include rejection cases")
        if not str(matrix.get("pass_condition", "")).strip():
            failures.append(f"{instrument_id}: matrix pass_condition is required")

    if not REVIEW_DOC_PATH.exists():
        failures.append("Docs/InstrumentArtworkProfessionalReview.zh-Hant.md is missing")
    else:
        doc_text = REVIEW_DOC_PATH.read_text(encoding="utf-8")
        for token in [
            "革胡",
            "嗩吶",
            "笙",
            "板胡",
            "二胡",
            "高胡",
            "中胡",
            "import_approved_artwork.py",
            "--approve",
            "iPhone 6.9",
            "iPad 13",
        ]:
            if token not in doc_text:
                failures.append(f"review doc missing required token: {token}")

    review_records = scorecard.get("review_records", [])
    if not isinstance(review_records, list):
        failures.append("review_records must be a list")
        review_records = []

    approved_ids = set()
    for record in review_records:
        record_failures_before = len(failures)
        review_record_is_approved(record, REQUIRED_CRITERIA, policy, failures)
        if len(failures) == record_failures_before and record.get("instrument_id") in REQUIRED_IDS:
            approved_ids.add(record["instrument_id"])

    missing_approved = sorted(REQUIRED_IDS - approved_ids)
    if missing_approved:
        message = "High-risk artwork scorecard has no approved professional review for: " + ", ".join(missing_approved)
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    print(f"High-risk artwork scorecard entries: {len(reviews_by_id)}/{len(REQUIRED_IDS)} instrument(s)")
    print(f"High-risk artwork approved review records: {len(approved_ids)}/{len(REQUIRED_IDS)} instrument(s)")

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nHigh-risk artwork review scorecard check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("High-risk artwork review scorecard check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
