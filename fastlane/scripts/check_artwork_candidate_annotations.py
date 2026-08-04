#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_IDS = {"gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"}
CANDIDATE_MANIFEST_PATH = ROOT / "Design" / "Review" / "ArtworkCandidates" / "candidate_manifest.json"
MORPHOLOGY_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "high_risk_artwork_morphology_specs.json"
)
REVIEW_DOC_PATH = ROOT / "Docs" / "InstrumentArtworkProfessionalReview.zh-Hant.md"
CORRECTION_DOC_PATH = ROOT / "Docs" / "InstrumentArtworkCorrectionPlan.zh-Hant.md"
REGEN_REQUEST_DOC_PATH = ROOT / "Docs" / "Phase1ArtworkRegenerationRequest.zh-Hant.md"

ACCEPTED_ANNOTATION_STATUS = "no_internal_text_labels"
BLOCKED_ANNOTATION_STATUSES = {
    "annotated_morphology_reference",
    "contains_internal_callouts",
    "unknown",
}
REQUIRED_DOC_TOKENS = [
    "不可加錯誤文字",
    "不看文字也能辨識",
    "no_visible_internal_text_labels",
    "annotation_status",
    "no_internal_text_labels",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    failures = []
    warnings = []

    candidate_manifest = load_json(CANDIDATE_MANIFEST_PATH)
    morphology = load_json(MORPHOLOGY_PATH)
    review_doc = REVIEW_DOC_PATH.read_text(encoding="utf-8") if REVIEW_DOC_PATH.exists() else ""
    correction_doc = CORRECTION_DOC_PATH.read_text(encoding="utf-8") if CORRECTION_DOC_PATH.exists() else ""
    regen_doc = REGEN_REQUEST_DOC_PATH.read_text(encoding="utf-8") if REGEN_REQUEST_DOC_PATH.exists() else ""
    docs_text = review_doc + "\n" + correction_doc + "\n" + regen_doc

    candidate_by_id = {item.get("instrument_id"): item for item in candidate_manifest.get("items", [])}
    spec_by_id = {item.get("instrument_id"): item for item in morphology.get("specs", [])}
    missing = sorted(REQUIRED_IDS - set(candidate_by_id))
    if missing:
        failures.append("candidate_manifest missing high-risk candidates: " + ", ".join(missing))

    for token in REQUIRED_DOC_TOKENS:
        if token not in docs_text:
            failures.append(f"artwork review docs missing token: {token}")
    if not REGEN_REQUEST_DOC_PATH.exists():
        failures.append("Missing Phase1ArtworkRegenerationRequest.zh-Hant.md")

    blocked = []
    for instrument_id in sorted(REQUIRED_IDS):
        candidate = candidate_by_id.get(instrument_id)
        spec = spec_by_id.get(instrument_id)
        if not candidate or not spec:
            continue

        path = ROOT / str(candidate.get("path", ""))
        if not path.exists():
            failures.append(f"{instrument_id}: candidate image missing: {candidate.get('path')}")

        annotation_status = str(candidate.get("annotation_status", "unknown"))
        if annotation_status != ACCEPTED_ANNOTATION_STATUS:
            blocked.append(f"{instrument_id}:{annotation_status}")

        if "visible incorrect text labels inside the image" not in morphology.get("global_rejection_rules", []):
            failures.append("morphology specs must reject visible incorrect text labels inside images")

        if candidate.get("candidate_status") == "replacement_ready" and annotation_status in BLOCKED_ANNOTATION_STATUSES:
            failures.append(f"{instrument_id}: annotated candidate cannot be replacement_ready")

    print(f"High-risk artwork candidate annotation status checked: {len(candidate_by_id)}/{len(REQUIRED_IDS)} candidate(s)")

    if blocked:
        message = (
            "High-risk artwork candidates still need no-internal-label review variants: "
            + ", ".join(blocked)
        )
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nArtwork candidate annotation check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Artwork candidate annotation check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
