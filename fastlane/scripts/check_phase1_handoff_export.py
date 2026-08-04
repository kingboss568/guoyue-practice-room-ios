#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EXPORT_MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Review"
    / "Phase1ProfessionalHandoff"
    / "handoff_export_manifest.json"
)
PHASE1_MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Review"
    / "Phase1ProfessionalHandoff"
    / "phase1_professional_handoff_manifest.json"
)
EXPORT_SCRIPT = ROOT / "fastlane" / "scripts" / "export_phase1_handoff_package.py"
DOC_PATH = ROOT / "Docs" / "Phase1ProfessionalHandoff.zh-Hant.md"

REQUIRED_IDS = ["erhu", "gaohu", "zhonghu", "gehu", "sheng", "suona", "banhu"]
REQUIRED_DOC_TOKENS = [
    "export_phase1_handoff_package.py",
    "Build/Phase1ProfessionalHandoff",
    "guoyue-phase1-real-audio-artwork-handoff.zip",
    "not approval evidence",
    "Suno",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    failures = []
    export_manifest = load_json(EXPORT_MANIFEST_PATH)
    phase1_manifest = load_json(PHASE1_MANIFEST_PATH)
    doc_text = DOC_PATH.read_text(encoding="utf-8") if DOC_PATH.exists() else ""

    if export_manifest.get("status") != "export_ready_for_external_delivery":
        failures.append("handoff export status must be export_ready_for_external_delivery")
    if "not approval evidence" not in str(export_manifest.get("policy", "")):
        failures.append("handoff export policy must state it is not approval evidence")
    if export_manifest.get("required_instrument_ids") != REQUIRED_IDS:
        failures.append("handoff export required_instrument_ids must preserve phase-1 order")
    if phase1_manifest.get("required_instrument_ids") != REQUIRED_IDS:
        failures.append("phase1 handoff required_instrument_ids must preserve phase-1 order")
    if not EXPORT_SCRIPT.exists():
        failures.append("Missing export_phase1_handoff_package.py")

    forbidden_tokens = set(export_manifest.get("forbidden_export_path_tokens", []))
    if not {".git", ".env", "._", "AuthKey", ".p8"} <= forbidden_tokens:
        failures.append("handoff export forbidden_export_path_tokens must block git/env/private key paths")

    for rel_path in export_manifest.get("shared_source_files", []):
        if not (ROOT / rel_path).is_file():
            failures.append(f"handoff export shared source missing: {rel_path}")
        if any(token and token in rel_path for token in forbidden_tokens):
            failures.append(f"handoff export shared source contains forbidden token: {rel_path}")

    per_instrument = {item.get("instrument_id"): item for item in export_manifest.get("per_instrument_exports", [])}
    if set(per_instrument) != set(REQUIRED_IDS):
        failures.append("handoff export per_instrument_exports must exactly match phase-1 instruments")
    for instrument_id in REQUIRED_IDS:
        item = per_instrument.get(instrument_id) or {}
        for key in ["release_template", "artwork_candidate", "artwork_approval_draft"]:
            rel_path = item.get(key, "")
            if not rel_path:
                failures.append(f"{instrument_id}: export {key} is required")
                continue
            if not (ROOT / rel_path).is_file():
                failures.append(f"{instrument_id}: export file missing for {key}: {rel_path}")
            if any(token and token in rel_path for token in forbidden_tokens):
                failures.append(f"{instrument_id}: export path contains forbidden token for {key}: {rel_path}")

    required_generated = set(export_manifest.get("required_generated_files", []))
    if not {"README.md", "PACKAGE_MANIFEST.json", "recording_inbox/README.md", "artwork_review/README.md"} <= required_generated:
        failures.append("handoff export required_generated_files must include README and package manifest outputs")
    if not str(export_manifest.get("output_root", "")).startswith("Build/Phase1ProfessionalHandoff"):
        failures.append("handoff export output_root must live under Build/Phase1ProfessionalHandoff")
    if not str(export_manifest.get("zip_filename", "")).endswith(".zip"):
        failures.append("handoff export zip_filename must be a zip")

    if not DOC_PATH.exists():
        failures.append("Missing Phase1ProfessionalHandoff.zh-Hant.md")
    else:
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"Phase1ProfessionalHandoff.zh-Hant.md missing token: {token}")

    print(f"Phase-1 handoff export manifest: {len(per_instrument)}/{len(REQUIRED_IDS)} instrument(s)")

    if failures:
        print("\nPhase-1 handoff export check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Phase-1 handoff export check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
