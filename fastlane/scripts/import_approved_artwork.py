#!/usr/bin/env python3
import argparse
import hashlib
import json
import shutil
import struct
from datetime import date
from pathlib import Path


REQUIRED_CONFIRMATIONS = {
    "professional_reviewer_confirmed": True,
    "matches_morphology_spec": True,
    "no_wrong_instrument_substitution": True,
    "no_fantasy_or_generated_detail_errors": True,
    "no_visible_internal_text_labels": True,
    "approved_for_app_store_submission": True,
}

STATUS_SWIFT = {
    "approved_after_review": "approvedAfterReview",
    "approved_after_professional_review": "approvedAfterProfessionalReview",
    "needs_regeneration": "needsRegeneration",
    "needs_differentiation": "needsDifferentiation",
    "reference_check_required": "referenceCheckRequired",
}


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def png_size(path):
    with path.open("rb") as f:
        header = f.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"Not a PNG file: {path}")
    return struct.unpack(">II", header[16:24])


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def write_json(path, payload):
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def swift_string(value):
    return json.dumps(str(value), ensure_ascii=False)


def swift_array(values):
    return "[" + ", ".join(swift_string(value) for value in values) + "]"


def regenerate_artwork_review_swift(root, audit_doc):
    records = []
    for item in audit_doc.get("items", []):
        status = item.get("status", "")
        swift_status = STATUS_SWIFT.get(status)
        if not swift_status:
            raise SystemExit(f"Unknown artwork review status for Swift catalog: {status}")
        records.append(
            "        ArtworkReviewRecord("
            + f"instrumentID: {swift_string(item.get('instrument_id', ''))}, "
            + f"instrumentName: {swift_string(item.get('name_zh', ''))}, "
            + f"status: .{swift_status}, "
            + f"risk: {swift_string(item.get('risk', ''))}, "
            + f"requiredChecks: {swift_array(item.get('required_checks', []))}"
            + ")"
        )

    high_risk_ids = ["gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"]
    swift = """import Foundation

enum ArtworkReviewStatus: String {
    case approvedAfterReview
    case approvedAfterProfessionalReview
    case needsRegeneration
    case needsDifferentiation
    case referenceCheckRequired

    var title: String {
        switch self {
        case .approvedAfterReview, .approvedAfterProfessionalReview:
            return "圖片已專業校對"
        case .needsRegeneration:
            return "圖片需重做"
        case .needsDifferentiation:
            return "形制差異待校正"
        case .referenceCheckRequired:
            return "圖片待參照校對"
        }
    }

    var isApproved: Bool {
        self == .approvedAfterReview || self == .approvedAfterProfessionalReview
    }
}

struct ArtworkReviewRecord: Identifiable, Hashable {
    let instrumentID: String
    let instrumentName: String
    let status: ArtworkReviewStatus
    let risk: String
    let requiredChecks: [String]

    var id: String { instrumentID }
}

enum ArtworkReviewCatalog {
    static let records: [ArtworkReviewRecord] = [
"""
    swift += ",\n".join(records)
    swift += """

    ]

    static let highRiskIDs: Set<String> = """
    swift += swift_array(high_risk_ids)
    swift += """

    static func record(for instrumentID: String) -> ArtworkReviewRecord? {
        records.first { $0.instrumentID == instrumentID }
    }

    static func record(for instrument: Instrument) -> ArtworkReviewRecord? {
        record(for: instrument.id)
    }
}
"""
    (root / "GuoYueZhiPu" / "Models" / "ArtworkReview.swift").write_text(
        swift,
        encoding="utf-8",
    )


def validate_approval(approval, instrument_id, candidate_item, spec_item, reference_item):
    failures = []

    def has_placeholder(value):
        if isinstance(value, str):
            return "TO_BE_FILLED" in value
        if isinstance(value, list):
            return any(has_placeholder(item) for item in value)
        if isinstance(value, dict):
            return any(has_placeholder(item) for item in value.values())
        return False

    if has_placeholder(approval):
        failures.append("approval metadata still contains TO_BE_FILLED placeholders")
    if approval.get("instrument_id") != instrument_id:
        failures.append("approval.instrument_id must match --instrument-id")
    for key in ["reviewed_at", "candidate_path", "candidate_sha256"]:
        if not str(approval.get(key, "")).strip():
            failures.append(f"approval.{key} is required")

    reviewer = approval.get("reviewer") or {}
    for key in ["name", "role"]:
        if not str(reviewer.get(key, "")).strip():
            failures.append(f"approval.reviewer.{key} is required")

    confirmations = approval.get("confirmations") or {}
    for key, expected in REQUIRED_CONFIRMATIONS.items():
        if confirmations.get(key) is not expected:
            failures.append(f"approval.confirmations.{key} must be {expected}")

    if approval.get("candidate_path") != candidate_item.get("path"):
        failures.append("approval.candidate_path must match candidate manifest path")
    if approval.get("candidate_sha256") != candidate_item.get("sha256"):
        failures.append("approval.candidate_sha256 must match candidate manifest hash")

    reviewed_urls = set(approval.get("reference_urls_reviewed") or [])
    required_urls = set(reference_item.get("reference_urls") or [])
    if len(reviewed_urls & required_urls) < min(2, len(required_urls)):
        failures.append("approval.reference_urls_reviewed must include at least two listed references")

    approved_must_show = set(approval.get("approved_must_show") or [])
    required_must_show = set(spec_item.get("must_show") or [])
    missing_must_show = sorted(required_must_show - approved_must_show)
    if missing_must_show:
        failures.append("approval.approved_must_show missing: " + ", ".join(missing_must_show))

    rejected_must_not_show = set(approval.get("rejected_must_not_show") or [])
    required_must_not_show = set(spec_item.get("must_not_show") or [])
    missing_must_not_show = sorted(required_must_not_show - rejected_must_not_show)
    if missing_must_not_show:
        failures.append("approval.rejected_must_not_show missing: " + ", ".join(missing_must_not_show))

    if failures:
        raise SystemExit("Invalid artwork approval metadata:\n- " + "\n- ".join(failures))


def main():
    parser = argparse.ArgumentParser(
        description="Validate and import a professionally approved high-risk instrument artwork candidate."
    )
    parser.add_argument("--instrument-id", required=True)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--approval", required=True, type=Path)
    parser.add_argument("--approve", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    candidate_path = args.candidate if args.candidate.is_absolute() else root / args.candidate
    approval_path = args.approval if args.approval.is_absolute() else root / args.approval

    candidate_manifest_path = root / "Design" / "Review" / "ArtworkCandidates" / "candidate_manifest.json"
    morphology_path = root / "Design" / "Source" / "InstrumentReferenceAudit" / "high_risk_artwork_morphology_specs.json"
    audit_path = root / "Design" / "Source" / "InstrumentReferenceAudit" / "instrument_reference_audit.json"
    reference_path = root / "Design" / "Source" / "InstrumentReferenceAudit" / "artwork_reference_sources.json"

    if not candidate_path.exists():
        raise SystemExit(f"Candidate PNG does not exist: {candidate_path}")
    if not approval_path.exists():
        raise SystemExit(f"Approval metadata does not exist: {approval_path}")

    width, height = png_size(candidate_path)
    if (width, height) != (900, 900):
        raise SystemExit(f"Candidate artwork must be 900x900 PNG, got {width}x{height}")

    candidate_manifest = load_json(candidate_manifest_path)
    morphology = load_json(morphology_path)
    audit = load_json(audit_path)
    references = load_json(reference_path)
    approval = load_json(approval_path)

    candidate_by_id = {item.get("instrument_id"): item for item in candidate_manifest.get("items", [])}
    spec_by_id = {item.get("instrument_id"): item for item in morphology.get("specs", [])}
    audit_by_id = {item.get("instrument_id"): item for item in audit.get("items", [])}
    reference_by_id = {item.get("instrument_id"): item for item in references.get("sources", [])}

    for label, lookup in [
        ("candidate manifest", candidate_by_id),
        ("morphology spec", spec_by_id),
        ("artwork audit", audit_by_id),
        ("reference source", reference_by_id),
    ]:
        if args.instrument_id not in lookup:
            raise SystemExit(f"{args.instrument_id}: missing from {label}")

    candidate_item = candidate_by_id[args.instrument_id]
    spec_item = spec_by_id[args.instrument_id]
    reference_item = reference_by_id[args.instrument_id]
    candidate_hash = sha256(candidate_path)
    if candidate_hash != candidate_item.get("sha256"):
        raise SystemExit(f"Candidate sha256 mismatch: {candidate_hash}")

    validate_approval(approval, args.instrument_id, candidate_item, spec_item, reference_item)

    print(
        f"{args.instrument_id}: approved artwork candidate validated "
        + f"{width}x{height}, sha256 {candidate_hash}"
    )

    if not args.approve:
        print("Dry run complete. Re-run with --approve to replace app artwork assets.")
        return

    design_target = root / "Design" / "Source" / "GeneratedInstruments" / f"instrument_{args.instrument_id}.png"
    asset_target = (
        root
        / "GuoYueZhiPu"
        / "Assets.xcassets"
        / f"instrument_{args.instrument_id}.imageset"
        / f"instrument_{args.instrument_id}.png"
    )
    approvals_root = root / "Design" / "Review" / "ArtworkCandidates" / "approvals"
    approvals_root.mkdir(parents=True, exist_ok=True)
    stored_approval = approvals_root / f"{args.instrument_id}.approval.json"

    shutil.copy2(candidate_path, design_target)
    shutil.copy2(candidate_path, asset_target)
    shutil.copy2(approval_path, stored_approval)

    for item in candidate_manifest.get("items", []):
        if item.get("instrument_id") == args.instrument_id:
            item["candidate_status"] = "replacement_ready"
            item["approval_path"] = str(stored_approval.relative_to(root))
            item["approved_at"] = approval["reviewed_at"]
            item["approved_by"] = approval["reviewer"]["name"]

    for item in morphology.get("specs", []):
        if item.get("instrument_id") == args.instrument_id:
            item["candidate_status"] = "replacement_ready"
            item["approval_path"] = str(stored_approval.relative_to(root))

    for item in audit.get("items", []):
        if item.get("instrument_id") == args.instrument_id:
            item["status"] = "approved_after_professional_review"
            item["approved_candidate_path"] = candidate_item["path"]
            item["approval_path"] = str(stored_approval.relative_to(root))
            item["approved_at"] = approval["reviewed_at"]

    today = date.today().isoformat()
    candidate_manifest["updated_at"] = today
    morphology["updated_at"] = today
    audit["updated_at"] = today
    write_json(candidate_manifest_path, candidate_manifest)
    write_json(morphology_path, morphology)
    write_json(audit_path, audit)
    regenerate_artwork_review_swift(root, audit)

    print(f"Approved {args.instrument_id} artwork and updated app asset catalog.")


if __name__ == "__main__":
    main()
