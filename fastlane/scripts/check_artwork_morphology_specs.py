#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


REQUIRED_IDS = {"gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"}
REQUIRED_LIST_FIELDS = {
    "must_show",
    "must_not_show",
    "relative_scale_rules",
    "professional_review_questions",
    "reference_basis",
}
CURRENT_STATUSES = {
    "approved_after_source_and_internal_visual_qc",
    "approved_after_professional_review",
}
READY_CANDIDATE_STATUS = "replacement_ready"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    spec_path = (
        root
        / "Design"
        / "Source"
        / "InstrumentReferenceAudit"
        / "high_risk_artwork_morphology_specs.json"
    )
    audit_path = (
        root
        / "Design"
        / "Source"
        / "InstrumentReferenceAudit"
        / "instrument_reference_audit.json"
    )
    reference_path = (
        root
        / "Design"
        / "Source"
        / "InstrumentReferenceAudit"
        / "artwork_reference_sources.json"
    )
    selection_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedPhotos"
        / "manifests"
        / "photo_source_selection.json"
    )

    failures = []
    warnings = []

    if not spec_path.exists():
        print(f"Missing high-risk artwork morphology specs: {spec_path.relative_to(root)}")
        return 1

    with spec_path.open(encoding="utf-8") as f:
        spec_doc = json.load(f)
    with audit_path.open(encoding="utf-8") as f:
        audit_doc = json.load(f)
    with reference_path.open(encoding="utf-8") as f:
        reference_doc = json.load(f)
    with selection_path.open(encoding="utf-8") as f:
        selection_doc = json.load(f)

    spec_ids = set(spec_doc.get("high_risk_instrument_ids", []))
    if spec_ids != REQUIRED_IDS:
        failures.append(
            "high_risk_instrument_ids mismatch: "
            + f"got {sorted(spec_ids)}, expected {sorted(REQUIRED_IDS)}"
        )

    specs = spec_doc.get("specs", [])
    spec_by_id = {item.get("instrument_id"): item for item in specs}
    missing_specs = sorted(REQUIRED_IDS - set(spec_by_id))
    unknown_specs = sorted(set(spec_by_id) - REQUIRED_IDS)
    if missing_specs:
        failures.append("Missing morphology specs: " + ", ".join(missing_specs))
    if unknown_specs:
        failures.append("Unknown morphology specs: " + ", ".join(unknown_specs))

    audit_by_id = {item.get("instrument_id"): item for item in audit_doc.get("items", [])}
    reference_by_id = {item.get("instrument_id"): item for item in reference_doc.get("sources", [])}
    selection_by_id = {
        item.get("instrument_id"): item
        for item in selection_doc.get("instruments", [])
    }

    pending = []
    for instrument_id in sorted(REQUIRED_IDS):
        item = spec_by_id.get(instrument_id)
        if not item:
            continue
        for key in ["name_zh", "priority", "candidate_file", "candidate_status"]:
            if not str(item.get(key, "")).strip():
                failures.append(f"{instrument_id}: field {key} is required")
        for key in REQUIRED_LIST_FIELDS:
            values = item.get(key)
            if not isinstance(values, list) or len([v for v in values if str(v).strip()]) < 2:
                failures.append(f"{instrument_id}: field {key} must include at least two entries")

        candidate_file = item.get("candidate_file", "")
        if candidate_file:
            candidate_path = root / candidate_file
            if not candidate_path.exists():
                failures.append(f"{instrument_id}: candidate_file missing: {candidate_file}")

        if instrument_id not in audit_by_id:
            failures.append(f"{instrument_id}: missing from instrument_reference_audit.json")
        if instrument_id not in reference_by_id:
            failures.append(f"{instrument_id}: missing from artwork_reference_sources.json")

        status = audit_by_id.get(instrument_id, {}).get("status")
        photo_status = selection_by_id.get(instrument_id, {}).get("status")
        if status not in CURRENT_STATUSES or photo_status not in CURRENT_STATUSES:
            pending.append(f"{instrument_id}:audit={status}, photo={photo_status}")

    print(f"High-risk artwork morphology specs: {len(spec_by_id)}/{len(REQUIRED_IDS)} instrument(s)")
    print(f"High-risk artwork source/visual approval gaps: {len(pending)}")

    if pending:
        message = (
            "High-risk artwork specs still lack approved source/visual QC: "
            + ", ".join(pending[:7])
            + (" ..." if len(pending) > 7 else "")
        )
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nHigh-risk artwork morphology spec check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("High-risk artwork morphology spec check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
