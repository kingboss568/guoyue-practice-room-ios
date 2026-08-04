#!/usr/bin/env python3
import hashlib
import json
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AUDITIONS = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "candidates"
    / "candidate_auditions.json"
)
APP_AUDIO = ROOT / "GuoYueZhiPu" / "Resources" / "Audio" / "Instruments"


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


def main() -> int:
    failures = []

    with AUDITIONS.open(encoding="utf-8") as f:
        auditions = json.load(f)

    if auditions.get("policy", {}).get("status") != "audition_only":
        failures.append("candidate audition policy status must be audition_only")

    items = auditions.get("items", [])
    for item in items:
        instrument_id = item.get("instrument_id", "")
        original_path = ROOT / item.get("local_original_path", "")
        audition_path = ROOT / item.get("local_audition_wav_path", "")
        app_path = APP_AUDIO / f"{instrument_id}.wav"

        if not original_path.exists():
            failures.append(f"{instrument_id}: original candidate file missing")
            continue
        if not audition_path.exists():
            failures.append(f"{instrument_id}: audition WAV missing")
            continue

        if sha256(original_path) != item.get("original_sha256"):
            failures.append(f"{instrument_id}: original sha256 mismatch")
        if sha256(audition_path) != item.get("audition_sha256"):
            failures.append(f"{instrument_id}: audition sha256 mismatch")

        details = inspect_wav(audition_path)
        if details["channels"] != 1:
            failures.append(f"{instrument_id}: audition WAV must be mono")
        if details["sample_rate_hz"] != 44100:
            failures.append(f"{instrument_id}: audition WAV must be 44100 Hz")
        if details["sample_width_bits"] != 16:
            failures.append(f"{instrument_id}: audition WAV must be 16-bit")
        if details["duration_seconds"] < 6:
            failures.append(f"{instrument_id}: audition WAV is too short")

        if item.get("status") != "local_audition_ready":
            failures.append(f"{instrument_id}: candidate status must be local_audition_ready")
        if not item.get("must_not_bundle_reason"):
            failures.append(f"{instrument_id}: must_not_bundle_reason is required")
        if item.get("license") in {"CC BY 4.0", "CC BY-SA 4.0"} and "Francesc Fort" in item.get("author", ""):
            if item.get("source_url", "").startswith("https://commons.wikimedia.org/wiki/File:") is False:
                failures.append(f"{instrument_id}: Wikimedia source URL is required")

        if app_path.exists() and sha256(app_path) == sha256(audition_path):
            failures.append(f"{instrument_id}: audition WAV has been copied into app bundle before approval")

    print(f"Candidate audio auditions: {len(items)} item(s)")

    if failures:
        print("\nCandidate audio audition check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Candidate audio audition check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
