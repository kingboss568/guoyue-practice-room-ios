#!/usr/bin/env python3
import argparse
import hashlib
import json
import wave
from pathlib import Path


APPROVED_STATUS = "approved"


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_wav(path):
    with wave.open(str(path), "rb") as wav:
        frame_count = wav.getnframes()
        sample_rate = wav.getframerate()
        return {
            "channels": wav.getnchannels(),
            "sample_rate_hz": sample_rate,
            "sample_width_bits": wav.getsampwidth() * 8,
            "duration_seconds": frame_count / sample_rate if sample_rate else 0,
        }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    data_path = root / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
    verified_root = root / "Design" / "Source" / "VerifiedAudio" / "Instruments"
    bundle_audio_root = root / "GuoYueZhiPu" / "Resources" / "Audio" / "Instruments"
    manifest_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedAudio"
        / "manifests"
        / "verified_audio_sources.json"
    )

    failures = []
    warnings = []

    apple_double = sorted(
        p.relative_to(root)
        for p in root.rglob("._*")
        if ".git" not in p.parts and "Build" not in p.parts
    )
    if apple_double:
        failures.append(f"AppleDouble files present: {len(apple_double)}")

    with data_path.open(encoding="utf-8") as f:
        data = json.load(f)

    if not manifest_path.exists():
        failures.append(
            "Missing verified audio source manifest: "
            + str(manifest_path.relative_to(root))
        )
        manifest = {"approved": []}
    else:
        with manifest_path.open(encoding="utf-8") as f:
            manifest = json.load(f)

    instruments = data.get("instruments", [])
    instrument_ids = {item["id"] for item in instruments}
    approved_entries = {
        item["instrument_id"]: item
        for item in manifest.get("approved", [])
        if item.get("status") == APPROVED_STATUS
    }
    external_entries = {
        item["instrument_id"]: item
        for item in manifest.get("external_references", [])
        if item.get("status") == "external_reference_not_bundled"
    }

    unknown_entries = sorted((set(approved_entries) | set(external_entries)) - instrument_ids)
    if unknown_entries:
        failures.append(
            "Audio manifest entries do not match app instruments: "
            + ", ".join(unknown_entries)
        )

    overlap = sorted(set(approved_entries) & set(external_entries))
    if overlap:
        failures.append(
            "Instrument cannot be both bundled-approved and external-only: "
            + ", ".join(overlap)
        )

    legacy_synth_rows = [
        item["id"]
        for item in instruments
        if "audio_waveform_type" in item or "pitch_frequency_hz" in item
    ]
    if legacy_synth_rows:
        failures.append(
            "Legacy synthetic-audio metadata is forbidden: "
            + ", ".join(legacy_synth_rows)
        )

    missing_coverage = [
        item["id"]
        for item in instruments
        if item["id"] not in approved_entries and item["id"] not in external_entries
    ]
    if missing_coverage:
        message = (
            "Missing approved local source or audited external real-instrument reference: "
            + f"{len(missing_coverage)}"
            + " ("
            + ", ".join(missing_coverage[:8])
            + (" ..." if len(missing_coverage) > 8 else "")
            + ")"
        )
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    for instrument_id, entry in sorted(external_entries.items()):
        for field in ["instrument_name_zh", "source_title", "source_url", "provider", "note"]:
            if not str(entry.get(field, "")).strip():
                failures.append(f"{instrument_id}: external reference field {field} is required")
        if not str(entry.get("source_url", "")).startswith("https://"):
            failures.append(f"{instrument_id}: external reference must use an HTTPS source URL")
        if entry.get("bundled") is not False:
            failures.append(f"{instrument_id}: external reference must declare bundled=false")
        if entry.get("quiz_eligible") is not False:
            failures.append(f"{instrument_id}: external reference must declare quiz_eligible=false")
        unexpected_bundle = bundle_audio_root / f"{instrument_id}.wav"
        if unexpected_bundle.exists():
            failures.append(
                f"{instrument_id}: external-only reference unexpectedly has a bundled WAV"
            )

    for instrument_id, entry in sorted(approved_entries.items()):
        source_path = root / entry.get("local_wav_path", "")
        bundle_path = root / entry.get(
            "bundle_wav_path",
            str(bundle_audio_root / f"{instrument_id}.wav"),
        )
        original_sources = entry.get("local_original_sources", [])

        if not source_path.exists():
            failures.append(
                f"{instrument_id}: approved source WAV missing at "
                + str(source_path.relative_to(root))
            )
            continue

        if not bundle_path.exists():
            failures.append(
                f"{instrument_id}: bundle WAV missing at "
                + str(bundle_path.relative_to(root))
            )
            continue

        if original_sources:
            declared_take_count = entry.get("source_take_count")
            if declared_take_count != len(original_sources):
                failures.append(
                    f"{instrument_id}: source_take_count does not match local_original_sources"
                )
            for original in original_sources:
                original_path = root / original.get("path", "")
                if not original_path.exists():
                    failures.append(
                        f"{instrument_id}: archived original take missing at "
                        + original.get("path", "")
                    )
                    continue
                if original.get("sha256") != sha256(original_path):
                    failures.append(
                        f"{instrument_id}: archived original take sha256 mismatch at "
                        + original.get("path", "")
                    )

        declared_hash = entry.get("sha256")
        actual_hash = sha256(source_path)
        bundle_hash = sha256(bundle_path)
        if declared_hash and actual_hash != declared_hash:
            failures.append(f"{instrument_id}: source WAV sha256 mismatch")
        if bundle_hash != actual_hash:
            failures.append(f"{instrument_id}: bundle WAV differs from approved source WAV")

        try:
            details = inspect_wav(source_path)
        except wave.Error as exc:
            failures.append(f"{instrument_id}: source WAV is invalid: {exc}")
            continue

        if details["channels"] != 1:
            failures.append(f"{instrument_id}: source WAV must be mono")
        if details["sample_rate_hz"] != 44100:
            failures.append(f"{instrument_id}: source WAV must be 44100 Hz")
        if details["sample_width_bits"] != 16:
            failures.append(f"{instrument_id}: source WAV must be 16-bit")
        if details["duration_seconds"] < 2:
            failures.append(f"{instrument_id}: source WAV is too short for review")

    approved_count = len(approved_entries)
    external_count = len(external_entries)
    total_count = len(instruments)
    if approved_count:
        print(f"Approved verified audio files: {approved_count}/{total_count}")
    if external_count:
        print(
            "Audited external real-instrument references (not bundled or quiz-eligible): "
            + f"{external_count}/{total_count}"
        )

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nAsset authenticity check failed:")
        for failure in failures:
            print(f"- {failure}")
        raise SystemExit(1)

    print("Asset authenticity check passed.")


if __name__ == "__main__":
    main()
