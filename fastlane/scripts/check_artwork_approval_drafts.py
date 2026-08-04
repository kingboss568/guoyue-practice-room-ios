#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_IDS = {"gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"}
APPROVAL_DRAFT_ROOT = ROOT / "Design" / "Review" / "ArtworkCandidates" / "approval_drafts"
CANDIDATE_MANIFEST = ROOT / "Design" / "Review" / "ArtworkCandidates" / "candidate_manifest.json"
MORPHOLOGY_SPECS = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "high_risk_artwork_morphology_specs.json"
)
REFERENCE_SOURCES = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "artwork_reference_sources.json"
)


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def contains_placeholder(value):
    if isinstance(value, str):
        return "TO_BE_FILLED" in value
    if isinstance(value, dict):
        return any(contains_placeholder(item) for item in value.values())
    if isinstance(value, list):
        return any(contains_placeholder(item) for item in value)
    return False


def main() -> int:
    failures = []

    candidate_manifest = load_json(CANDIDATE_MANIFEST)
    morphology = load_json(MORPHOLOGY_SPECS)
    references = load_json(REFERENCE_SOURCES)

    candidate_by_id = {item.get("instrument_id"): item for item in candidate_manifest.get("items", [])}
    spec_by_id = {item.get("instrument_id"): item for item in morphology.get("specs", [])}
    reference_by_id = {item.get("instrument_id"): item for item in references.get("sources", [])}

    draft_paths = sorted(
        path
        for path in APPROVAL_DRAFT_ROOT.glob("*.approval.draft.json")
        if not path.name.startswith("._")
    )
    draft_ids = {path.name.removesuffix(".approval.draft.json") for path in draft_paths}
    missing = sorted(REQUIRED_IDS - draft_ids)
    unknown = sorted(draft_ids - REQUIRED_IDS)
    if missing:
        failures.append("Missing approval drafts: " + ", ".join(missing))
    if unknown:
        failures.append("Unknown approval drafts: " + ", ".join(unknown))

    for instrument_id in sorted(REQUIRED_IDS):
        path = APPROVAL_DRAFT_ROOT / f"{instrument_id}.approval.draft.json"
        if not path.exists():
            continue

        draft = load_json(path)
        candidate = candidate_by_id.get(instrument_id)
        spec = spec_by_id.get(instrument_id)
        reference = reference_by_id.get(instrument_id)
        if not candidate or not spec or not reference:
            failures.append(f"{instrument_id}: missing candidate/spec/reference source")
            continue

        if draft.get("draft_only") is not True:
            failures.append(f"{instrument_id}: approval draft must keep draft_only=true")
        if not contains_placeholder(draft):
            failures.append(f"{instrument_id}: approval draft must retain TO_BE_FILLED placeholders")
        if draft.get("instrument_id") != instrument_id:
            failures.append(f"{instrument_id}: draft instrument_id mismatch")
        if draft.get("instrument_name_zh") != spec.get("name_zh"):
            failures.append(f"{instrument_id}: draft instrument_name_zh mismatch")
        if draft.get("candidate_path") != candidate.get("path"):
            failures.append(f"{instrument_id}: draft candidate_path must match candidate manifest")
        if draft.get("candidate_sha256") != candidate.get("sha256"):
            failures.append(f"{instrument_id}: draft candidate_sha256 must match candidate manifest")
        if draft.get("candidate_size") != candidate.get("size"):
            failures.append(f"{instrument_id}: draft candidate_size must match candidate manifest")

        reviewed_urls = set(draft.get("reference_urls_reviewed") or [])
        reference_urls = set(reference.get("reference_urls") or [])
        if len(reviewed_urls & reference_urls) < 2:
            failures.append(f"{instrument_id}: draft must include at least two known reference URLs")

        if set(draft.get("approved_must_show") or []) != set(spec.get("must_show") or []):
            failures.append(f"{instrument_id}: approved_must_show must match morphology spec")
        if set(draft.get("rejected_must_not_show") or []) != set(spec.get("must_not_show") or []):
            failures.append(f"{instrument_id}: rejected_must_not_show must match morphology spec")
        if set(draft.get("relative_scale_rules_verified") or []) != set(spec.get("relative_scale_rules") or []):
            failures.append(f"{instrument_id}: relative_scale_rules_verified must match morphology spec")
        if set(draft.get("professional_review_questions") or []) != set(spec.get("professional_review_questions") or []):
            failures.append(f"{instrument_id}: professional_review_questions must match morphology spec")

        source_features = draft.get("source_features_to_verify") or []
        if len([item for item in source_features if str(item).strip()]) < 4:
            failures.append(f"{instrument_id}: source_features_to_verify must include reference-backed features")

        confirmations = draft.get("confirmations") or {}
        for key in [
            "professional_reviewer_confirmed",
            "matches_morphology_spec",
            "no_wrong_instrument_substitution",
            "no_fantasy_or_generated_detail_errors",
            "no_visible_internal_text_labels",
            "approved_for_app_store_submission",
        ]:
            if confirmations.get(key) is not True:
                failures.append(f"{instrument_id}: confirmation {key} must be true in approval draft")

    print(f"Artwork approval drafts: {len(draft_ids & REQUIRED_IDS)}/{len(REQUIRED_IDS)} high-risk instrument(s)")

    if failures:
        print("\nArtwork approval draft check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Artwork approval draft check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
