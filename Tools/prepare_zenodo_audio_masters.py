#!/usr/bin/env python3
"""Convert selected Zenodo FolkMusic candidates into App master WAV files."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path


SOURCE_RECORD = "https://zenodo.org/records/8012071"
SOURCE_DOI = "10.5281/zenodo.8012071"
AUTHORS = ["Zhen Li", "Hao Zhou", "Shusong Xing", "Binhui Wang"]
LICENSE = "CC BY 4.0"
LICENSE_URL = "https://creativecommons.org/licenses/by/4.0/"

INSTRUMENTS = {
    "bo": {"name_zh": "鈸", "dataset_label": "Ba"},
    "xiao": {"name_zh": "簫", "dataset_label": "Dongxiao"},
    "erhu": {"name_zh": "二胡", "dataset_label": "Erhu"},
    "guzheng": {"name_zh": "古箏", "dataset_label": "Guzheng"},
    "liuqin": {"name_zh": "柳琴", "dataset_label": "Liuqin"},
    "pipa": {"name_zh": "琵琶", "dataset_label": "Pipa"},
    "sanxian": {"name_zh": "三弦", "dataset_label": "Sanxian"},
    "suona": {"name_zh": "嗩吶", "dataset_label": "Suona"},
    "yangqin": {"name_zh": "揚琴", "dataset_label": "Yangqin"},
    "zhongruan": {"name_zh": "中阮", "dataset_label": "Zhongruan"},
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def probe(path: Path) -> dict:
    completed = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "a:0",
            "-show_entries",
            "stream=codec_name,sample_rate,channels,bits_per_sample:format=duration",
            "-of",
            "json",
            str(path),
        ],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return json.loads(completed.stdout)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("signal_qc", type=Path)
    parser.add_argument("master_dir", type=Path)
    parser.add_argument("bundle_dir", type=Path)
    parser.add_argument("output_manifest", type=Path)
    args = parser.parse_args()

    qc = json.loads(args.signal_qc.read_text(encoding="utf-8"))
    args.master_dir.mkdir(parents=True, exist_ok=True)
    args.bundle_dir.mkdir(parents=True, exist_ok=True)
    entries: list[dict] = []

    for instrument_id, details in INSTRUMENTS.items():
        source = Path(qc["recommendations"][instrument_id])
        master = args.master_dir / f"{instrument_id}.wav"
        bundle = args.bundle_dir / f"{instrument_id}.wav"
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                str(source),
                "-ac",
                "1",
                "-ar",
                "44100",
                "-af",
                "loudnorm=I=-18:TP=-1.5:LRA=7,afade=t=in:st=0:d=0.02,afade=t=out:st=2.92:d=0.08",
                "-c:a",
                "pcm_s16le",
                str(master),
            ],
            check=True,
        )
        shutil.copy2(master, bundle)
        metadata = probe(master)
        stream = metadata["streams"][0]
        entries.append(
            {
                "instrument_id": instrument_id,
                "instrument_name_zh": details["name_zh"],
                "dataset_label": details["dataset_label"],
                "source_title": f"China traditional music instrument dataset — {source.parent.name}/{source.name}",
                "source_url": SOURCE_RECORD,
                "doi": SOURCE_DOI,
                "authors": AUTHORS,
                "license": LICENSE,
                "license_url": LICENSE_URL,
                "source_mp3_path": str(source),
                "source_mp3_sha256": sha256(source),
                "master_wav_path": str(master),
                "bundle_wav_path": str(bundle),
                "master_wav_sha256": sha256(master),
                "duration_seconds": round(float(metadata["format"]["duration"]), 6),
                "format": {
                    "codec": stream["codec_name"],
                    "sample_rate_hz": int(stream["sample_rate"]),
                    "channels": int(stream["channels"]),
                    "bit_depth": int(stream["bits_per_sample"]),
                },
                "derivative_actions": [
                    "selected from five evenly spaced isolated-instrument candidates using signal-quality screening",
                    "converted to mono 44100 Hz 16-bit PCM WAV",
                    "normalized to -18 LUFS / -1.5 dBTP target",
                    "applied 20 ms fade-in and 80 ms fade-out",
                ],
                "status": "approved_source_license_format",
                "professional_listening_review": "required_before_submission",
            }
        )

    manifest = {
        "schema_version": 1,
        "source_record": SOURCE_RECORD,
        "source_doi": SOURCE_DOI,
        "license": LICENSE,
        "policy_note": "These files are real isolated-instrument recordings with source, license, and signal QC. A named professional listening review remains a release gate.",
        "entries": entries,
    }
    args.output_manifest.parent.mkdir(parents=True, exist_ok=True)
    args.output_manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Prepared {len(entries)} real-instrument WAV masters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
