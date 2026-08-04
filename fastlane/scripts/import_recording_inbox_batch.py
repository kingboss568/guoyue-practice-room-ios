#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PACK_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "full_open_recording_delivery_pack.json"
)
PRIORITY_PACK_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "priority1_recording_delivery_pack.json"
)
SCORECARD_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "professional_listening_review_scorecard.json"
)
IMPORT_SCRIPT = ROOT / "fastlane" / "scripts" / "import_verified_audio.py"
CHECK_INBOX_SCRIPT = ROOT / "fastlane" / "scripts" / "check_recording_inbox.py"
CHECK_PHASE1_INBOX_SCRIPT = ROOT / "fastlane" / "scripts" / "check_phase1_recording_inbox.py"
CHECK_SCORECARD_SCRIPT = ROOT / "fastlane" / "scripts" / "check_professional_listening_scorecard.py"


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def approved_review_ids():
    scorecard = load_json(SCORECARD_PATH)
    return {
        record.get("instrument_id")
        for record in scorecard.get("review_records", [])
        if record.get("decision") == "approved_for_import"
    }


def item_is_complete(item):
    folder = ROOT / item["delivery_folder"]
    if not folder.exists():
        return False, "delivery folder missing"
    expected_files = {take["filename"] for take in item.get("take_specs", [])}
    expected_files.add(f"{item['instrument_id']}.release.json")
    actual_files = {path.name for path in folder.iterdir() if path.is_file() and not path.name.startswith(".")}
    missing = sorted(expected_files - actual_files)
    if missing:
        return False, "missing " + ", ".join(missing)
    return True, "complete"


def build_import_command(item, approve):
    instrument_id = item["instrument_id"]
    folder = ROOT / item["delivery_folder"]
    command = [
        sys.executable,
        str(IMPORT_SCRIPT),
        "--instrument-id",
        instrument_id,
        "--release",
        str(folder / f"{instrument_id}.release.json"),
        "--minimum-take-seconds",
        "6",
    ]
    for take in item.get("take_specs", []):
        command.extend(["--source", str(folder / take["filename"])])
    if approve:
        command.append("--approve")
    return command


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Dry-run or approve-import complete, professionally reviewed recording inbox deliveries."
    )
    parser.add_argument(
        "--pack",
        choices=["full", "priority1"],
        default="full",
        help="Use the complete open-instrument pack or the priority-1 pack including sheng reverify.",
    )
    parser.add_argument(
        "--instrument-id",
        action="append",
        help="Limit to one instrument. Repeat to import several selected instruments.",
    )
    parser.add_argument(
        "--approve",
        action="store_true",
        help="Actually import approved inbox recordings into verified audio assets.",
    )
    parser.add_argument(
        "--allow-unreviewed",
        action="store_true",
        help="Dry-run complete inbox folders without a professional approved_for_import review. Ignored with --approve.",
    )
    args = parser.parse_args()

    pack_path = PRIORITY_PACK_PATH if args.pack == "priority1" else PACK_PATH
    pack = load_json(pack_path)
    requested_ids = set(args.instrument_id or pack.get("required_instrument_ids", []))
    pack_by_id = {item["instrument_id"]: item for item in pack.get("items", [])}
    unknown = sorted(requested_ids - set(pack_by_id))
    if unknown:
        raise SystemExit("Unknown requested instrument(s): " + ", ".join(unknown))

    print("Running inbox and professional listening preflight...")
    inbox_script = CHECK_PHASE1_INBOX_SCRIPT if args.pack == "priority1" else CHECK_INBOX_SCRIPT
    subprocess.run([sys.executable, str(inbox_script), "--strict"], cwd=ROOT, check=True)
    subprocess.run([sys.executable, str(CHECK_SCORECARD_SCRIPT)], cwd=ROOT, check=True)

    approved_ids = approved_review_ids()
    selected = []
    skipped = []
    for instrument_id in sorted(requested_ids):
        item = pack_by_id[instrument_id]
        complete, reason = item_is_complete(item)
        if not complete:
            skipped.append((instrument_id, reason))
            continue
        if instrument_id not in approved_ids:
            if args.approve:
                skipped.append((instrument_id, "missing approved_for_import professional review"))
                continue
            if not args.allow_unreviewed:
                skipped.append((instrument_id, "missing approved_for_import professional review"))
                continue
        selected.append(item)

    print(f"Recording inbox import candidates: {len(selected)}")
    for instrument_id, reason in skipped:
        print(f"SKIP {instrument_id}: {reason}")

    if not selected:
        print("No complete approved inbox recordings to import.")
        return 0

    for item in selected:
        instrument_id = item["instrument_id"]
        print(f"\n{'APPROVE' if args.approve else 'DRY-RUN'} {instrument_id}")
        subprocess.run(build_import_command(item, args.approve), cwd=ROOT, check=True)

    if args.approve:
        print("\nApproved inbox recordings imported. Run STRICT_READY=1 readiness after screenshots and StoreKit are current.")
    else:
        print("\nDry-run complete. Re-run with --approve after final human confirmation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
