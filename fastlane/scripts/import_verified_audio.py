#!/usr/bin/env python3
import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
import wave
from datetime import date
from pathlib import Path


REQUIRED_CONFIRMATIONS = {
    "real_instrument_recording": True,
    "commercial_app_distribution": True,
    "derivative_processing_allowed": True,
    "global_perpetual_use": True,
    "not_ai_generated": True,
    "not_vst_or_sample_library": True,
    "not_ripped_from_streaming_or_video": True,
}

ALLOWED_SOURCE_TYPES = {
    "commissioned_real_recording",
    "public_domain_real_recording",
    "cc0_real_recording",
    "cc_by_real_recording",
    "direct_permission_real_recording",
}

ALLOWED_COMPOSITION_STATUS = {
    "single_notes_or_original_improvisation",
    "public_domain",
    "licensed",
    "not_applicable_percussion_hit",
}


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_wav(path):
    with wave.open(str(path), "rb") as wav:
        frames = wav.getnframes()
        sample_rate = wav.getframerate()
        return {
            "channels": wav.getnchannels(),
            "sample_rate_hz": sample_rate,
            "sample_width_bits": wav.getsampwidth() * 8,
            "duration_seconds": frames / sample_rate if sample_rate else 0,
        }


def probe_duration_seconds(path):
    command = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(path),
    ]
    result = subprocess.run(command, check=True, stdout=subprocess.PIPE, text=True)
    return float(result.stdout.strip())


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def write_json(path, payload):
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def validate_release(release, instrument_id):
    failures = []

    def has_placeholder(value):
        if isinstance(value, str):
            return "TO_BE_FILLED" in value
        if isinstance(value, dict):
            return any(has_placeholder(child) for child in value.values())
        if isinstance(value, list):
            return any(has_placeholder(child) for child in value)
        return False

    if release.get("template_only") is True:
        failures.append("release metadata is a template; copy it to inbox and fill real values first")
    if has_placeholder(release):
        failures.append("release metadata still contains TO_BE_FILLED placeholders")

    if release.get("instrument_id") != instrument_id:
        failures.append("release.instrument_id must match --instrument-id")

    source_type = release.get("source_type")
    if source_type not in ALLOWED_SOURCE_TYPES:
        failures.append(
            "release.source_type must be one of: " + ", ".join(sorted(ALLOWED_SOURCE_TYPES))
        )

    for key in [
        "instrument_name_zh",
        "source_title",
        "performer_or_source",
        "recording_date",
        "license",
        "license_url_or_document",
    ]:
        if not str(release.get(key, "")).strip():
            failures.append(f"release.{key} is required")

    composition_status = release.get("composition_rights_status")
    if composition_status not in ALLOWED_COMPOSITION_STATUS:
        failures.append(
            "release.composition_rights_status must be one of: "
            + ", ".join(sorted(ALLOWED_COMPOSITION_STATUS))
        )

    confirmations = release.get("confirmations") or {}
    for key, expected in REQUIRED_CONFIRMATIONS.items():
        if confirmations.get(key) is not expected:
            failures.append(f"release.confirmations.{key} must be {expected}")

    if failures:
        raise SystemExit("Invalid release metadata:\n- " + "\n- ".join(failures))


def convert_to_app_wav(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    duration = probe_duration_seconds(source)
    fade_out_start = max(duration - 0.5, 0)
    command = [
        "ffmpeg",
        "-y",
        "-i",
        str(source),
        "-ac",
        "1",
        "-ar",
        "44100",
        "-sample_fmt",
        "s16",
        "-af",
        f"loudnorm=I=-18:TP=-2:LRA=11,afade=t=in:st=0:d=0.03,afade=t=out:st={fade_out_start:.3f}:d=0.5",
        str(destination),
    ]
    subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def concatenate_wavs(sources, destination, silence_seconds=0.6):
    if len(sources) == 1:
        shutil.copy2(sources[0], destination)
        return

    silence_frames = b"\x00\x00" * int(44100 * silence_seconds)
    with wave.open(str(sources[0]), "rb") as first:
        params = first.getparams()
        frames = [first.readframes(first.getnframes())]

    for source in sources[1:]:
        with wave.open(str(source), "rb") as current:
            if current.getparams()[:4] != params[:4]:
                raise SystemExit(f"Converted take format mismatch: {source}")
            frames.append(current.readframes(current.getnframes()))

    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setparams(params)
        for index, frame_data in enumerate(frames):
            if index:
                output.writeframes(silence_frames)
            output.writeframes(frame_data)


def main():
    parser = argparse.ArgumentParser(
        description="Validate and import a verified real-instrument recording into the app bundle."
    )
    parser.add_argument("--instrument-id", required=True)
    parser.add_argument(
        "--source",
        required=True,
        action="append",
        type=Path,
        help="Source recording path. Repeat for multiple performer takes.",
    )
    parser.add_argument("--release", required=True, type=Path)
    parser.add_argument(
        "--minimum-take-seconds",
        default=2.0,
        type=float,
        help="Minimum duration required after converting each supplied take.",
    )
    parser.add_argument(
        "--approve",
        action="store_true",
        help="Write converted WAV files and update the verified audio manifest.",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    data_path = root / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
    manifest_path = (
        root
        / "Design"
        / "Source"
        / "VerifiedAudio"
        / "manifests"
        / "verified_audio_sources.json"
    )
    source_paths = [
        source if source.is_absolute() else root / source
        for source in args.source
    ]
    release_path = args.release if args.release.is_absolute() else root / args.release

    for source_path in source_paths:
        if not source_path.exists():
            raise SystemExit(f"Source audio does not exist: {source_path}")
    if not release_path.exists():
        raise SystemExit(f"Release metadata does not exist: {release_path}")

    data = load_json(data_path)
    instrument_by_id = {item["id"]: item for item in data.get("instruments", [])}
    if args.instrument_id not in instrument_by_id:
        raise SystemExit(f"Unknown instrument id: {args.instrument_id}")

    release = load_json(release_path)
    validate_release(release, args.instrument_id)

    with tempfile.TemporaryDirectory() as tmpdir:
        converted_takes = []
        for index, source_path in enumerate(source_paths, start=1):
            converted_take = Path(tmpdir) / f"{args.instrument_id}.take{index:02d}.wav"
            convert_to_app_wav(source_path, converted_take)
            take_details = inspect_wav(converted_take)
            if take_details["duration_seconds"] < args.minimum_take_seconds:
                raise SystemExit(
                    f"Converted take {index} is too short: "
                    + f"{take_details['duration_seconds']:.2f}s"
                )
            converted_takes.append(converted_take)
            print(
                f"{args.instrument_id}: take {index} "
                + f"{take_details['duration_seconds']:.2f}s "
                + f"{take_details['channels']}ch {take_details['sample_rate_hz']}Hz "
                + f"{take_details['sample_width_bits']}-bit"
            )

        converted = Path(tmpdir) / f"{args.instrument_id}.wav"
        concatenate_wavs(converted_takes, converted)
        details = inspect_wav(converted)
        converted_hash = sha256(converted)

        print(
            f"{args.instrument_id}: master {details['duration_seconds']:.2f}s "
            f"{details['channels']}ch {details['sample_rate_hz']}Hz "
            f"{details['sample_width_bits']}-bit"
        )
        print(f"{args.instrument_id}: sha256 {converted_hash}")

        if not args.approve:
            print("Dry run complete. Re-run with --approve to update app assets.")
            return

        originals_root = root / "Design" / "Source" / "VerifiedAudio" / "originals"
        verified_root = root / "Design" / "Source" / "VerifiedAudio" / "Instruments"
        bundle_root = root / "GuoYueZhiPu" / "Resources" / "Audio" / "Instruments"
        releases_root = root / "Design" / "Source" / "VerifiedAudio" / "releases"

        originals_root.mkdir(parents=True, exist_ok=True)
        verified_root.mkdir(parents=True, exist_ok=True)
        bundle_root.mkdir(parents=True, exist_ok=True)
        releases_root.mkdir(parents=True, exist_ok=True)

        local_originals = []
        if len(source_paths) == 1:
            source_path = source_paths[0]
            original_extension = source_path.suffix.lower() or ".audio"
            local_original = originals_root / f"{args.instrument_id}.verified{original_extension}"
            shutil.copy2(source_path, local_original)
            local_originals.append(local_original)
        else:
            instrument_originals_root = originals_root / args.instrument_id
            instrument_originals_root.mkdir(parents=True, exist_ok=True)
            for index, source_path in enumerate(source_paths, start=1):
                original_extension = source_path.suffix.lower() or ".audio"
                local_original = (
                    instrument_originals_root
                    / f"{args.instrument_id}.take{index:02d}.verified{original_extension}"
                )
                shutil.copy2(source_path, local_original)
                local_originals.append(local_original)

        local_release = releases_root / f"{args.instrument_id}.release.json"
        local_wav = verified_root / f"{args.instrument_id}.wav"
        bundle_wav = bundle_root / f"{args.instrument_id}.wav"

        shutil.copy2(release_path, local_release)
        shutil.copy2(converted, local_wav)
        shutil.copy2(converted, bundle_wav)

    manifest = load_json(manifest_path)
    approved = [
        item
        for item in manifest.get("approved", [])
        if item.get("instrument_id") != args.instrument_id
    ]
    approved.append(
        {
            "instrument_id": args.instrument_id,
            "instrument_name_zh": release["instrument_name_zh"],
            "source_title": release["source_title"],
            "source_url": release.get("source_url", ""),
            "original_source_url": release.get("original_source_url", ""),
            "author": release["performer_or_source"],
            "source_date": release["recording_date"],
            "source_type": release["source_type"],
            "license": release["license"],
            "license_url": release["license_url_or_document"],
            "license_review": release.get("license_review", "Release metadata validated locally."),
            "composition_rights_status": release["composition_rights_status"],
            "derivative_actions": [
                "validated release metadata",
                "copied original source recording take(s)",
                "converted to mono 44100 Hz 16-bit WAV",
                "concatenated multiple takes with short silence gaps" if len(source_paths) > 1 else "selected one take as app master",
                "applied loudness normalization and short fades",
            ],
            "source_take_count": len(local_originals),
            "local_original_path": str(local_originals[0].relative_to(root)),
            "local_original_sources": [
                {
                    "take_index": index,
                    "path": str(path.relative_to(root)),
                    "sha256": sha256(path),
                }
                for index, path in enumerate(local_originals, start=1)
            ],
            "local_release_path": str(local_release.relative_to(root)),
            "local_wav_path": str(local_wav.relative_to(root)),
            "bundle_wav_path": str(bundle_wav.relative_to(root)),
            "sha256": sha256(local_wav),
            "duration_seconds": round(inspect_wav(local_wav)["duration_seconds"], 5),
            "approved_at": date.today().isoformat(),
            "status": "approved",
        }
    )
    approved.sort(key=lambda item: item["instrument_id"])
    manifest["approved"] = approved
    manifest["open_instrument_ids"] = [
        item
        for item in manifest.get("open_instrument_ids", [])
        if item != args.instrument_id
    ]
    manifest["updated_at"] = date.today().isoformat()
    write_json(manifest_path, manifest)

    print(f"Approved {args.instrument_id} and updated {manifest_path.relative_to(root)}")


if __name__ == "__main__":
    main()
