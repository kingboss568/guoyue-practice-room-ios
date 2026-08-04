#!/usr/bin/env python3
"""Create deterministic signal-quality measurements for audio candidates."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import subprocess
from pathlib import Path


def run(command: list[str]) -> str:
    completed = subprocess.run(
        command,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return completed.stdout


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def last_float(pattern: str, text: str) -> float | None:
    matches = re.findall(pattern, text)
    if not matches:
        return None
    value = matches[-1]
    if value.lower() in {"-inf", "inf", "nan"}:
        return None
    return float(value)


def probe(path: Path) -> dict[str, object]:
    probe_output = run(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "a:0",
            "-show_entries",
            "stream=codec_name,sample_rate,channels,bit_rate:format=duration",
            "-of",
            "json",
            str(path),
        ]
    )
    metadata = json.loads(probe_output)
    stream = metadata["streams"][0]
    analysis = run(
        [
            "ffmpeg",
            "-hide_banner",
            "-nostats",
            "-i",
            str(path),
            "-af",
            "silencedetect=noise=-50dB:d=0.20,astats=metadata=1:reset=0",
            "-f",
            "null",
            "-",
        ]
    )
    silence_durations = [
        float(value)
        for value in re.findall(r"silence_duration: ([0-9.]+)", analysis)
    ]
    duration = float(metadata["format"]["duration"])
    peak_db = last_float(r"Peak level dB: ([\-0-9.infna]+)", analysis)
    rms_db = last_float(r"RMS level dB: ([\-0-9.infna]+)", analysis)
    silence_seconds = sum(silence_durations)

    penalty = 0.0
    if duration < 2.5:
        penalty += (2.5 - duration) * 50
    if peak_db is None:
        penalty += 100
    elif peak_db > -0.10:
        penalty += 30 + (peak_db + 0.10) * 20
    if rms_db is None:
        penalty += 100
    else:
        penalty += abs(rms_db + 18.0)
        if rms_db < -36:
            penalty += 40
        if rms_db > -5:
            penalty += 20
    penalty += silence_seconds * 25

    return {
        "file": str(path),
        "sha256": sha256(path),
        "codec": stream.get("codec_name"),
        "sample_rate_hz": int(stream["sample_rate"]),
        "channels": int(stream["channels"]),
        "bit_rate": int(stream["bit_rate"]) if stream.get("bit_rate") else None,
        "duration_seconds": round(duration, 6),
        "peak_dbfs": round(peak_db, 4) if peak_db is not None else None,
        "rms_dbfs": round(rms_db, 4) if rms_db is not None else None,
        "silence_seconds": round(silence_seconds, 6),
        "signal_quality_score": round(penalty, 4),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("output_json", type=Path)
    args = parser.parse_args()

    candidates: list[dict[str, object]] = []
    for path in sorted(args.input_dir.glob("*/*.mp3")):
        candidates.append(probe(path))

    recommendations: dict[str, str] = {}
    instrument_ids = sorted({Path(item["file"]).parent.name for item in candidates})
    for instrument_id in instrument_ids:
        matches = [
            item
            for item in candidates
            if Path(item["file"]).parent.name == instrument_id
        ]
        winner = min(matches, key=lambda item: float(item["signal_quality_score"]))
        recommendations[instrument_id] = str(winner["file"])

    output = {
        "analysis_policy": {
            "silence_threshold_db": -50,
            "minimum_silence_duration_seconds": 0.20,
            "target_rms_dbfs": -18,
            "note": "Signal score is a technical screening aid, not a substitute for professional listening review.",
        },
        "recommendations": recommendations,
        "candidates": candidates,
    }
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Analyzed {len(candidates)} candidates")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
