#!/usr/bin/env python3
"""Prepare the audited Commons/Freesound masters not covered by Zenodo 8012071."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path


SOURCES = {
    "banhu": {
        "name_zh": "板胡",
        "source": "Design/Source/VerifiedAudio/originals/commons/banhu.Banhu.ogg",
        "start": 2.0,
        "duration": 3.0,
        "title": "Banhu.ogg",
        "source_url": "https://commons.wikimedia.org/wiki/File:Banhu.ogg",
        "author": "Francesc Fort",
        "license": "CC BY-SA 4.0",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/",
        "source_note": "Real banhu sound published on Wikimedia Commons.",
    },
    "gaohu": {
        "name_zh": "高胡",
        "source": "Design/Source/VerifiedAudio/originals/commons/gaohu.Lianhuankou.ogg",
        "start": 12.0,
        "duration": 5.0,
        "title": "連環扣（高胡獨奏）",
        "source_url": "https://commons.wikimedia.org/wiki/File:%E8%BF%9E%E7%8E%AF%E6%89%A3.ogg",
        "author": "張沛堅 (Zhang Peijian)",
        "license": "CC BY-SA 4.0",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/",
        "source_note": "Real gaohu solo performance published on Wikimedia Commons with a VRT permission ticket.",
    },
    "luo": {
        "name_zh": "鑼",
        "source": "Design/Source/VerifiedAudio/originals/commons/luo.Chinese_Gong.wav",
        "start": 0.45,
        "duration": 5.0,
        "title": "Chinese Gong finish session",
        "source_url": "https://commons.wikimedia.org/wiki/File:240382_the-very-real-horst_chinese-gong-finish-session-2014-06-10-29-143.wav",
        "author": "the_very_Real_Horst",
        "license": "CC0 1.0",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "source_note": "Recording of a large Chinese gong, mirrored from Freesound to Wikimedia Commons.",
    },
    "muyu": {
        "name_zh": "木魚",
        "source": "Design/Source/VerifiedAudio/originals/freesound/muyu.205999.hq-preview.mp3",
        "start": 3.8,
        "duration": 5.0,
        "title": "Fischtrommel_Muyu.mp3",
        "source_url": "https://freesound.org/people/the_very_Real_Horst/sounds/205999/",
        "author": "the_very_Real_Horst",
        "license": "CC BY 4.0",
        "license_url": "https://creativecommons.org/licenses/by/4.0/",
        "source_note": "Real Chinese wooden fish recording; high-quality Freesound preview indexed by Openverse.",
    },
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def probe(path: Path) -> dict:
    output = subprocess.run(
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
    ).stdout
    return json.loads(output)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("master_dir", type=Path)
    parser.add_argument("bundle_dir", type=Path)
    parser.add_argument("output_manifest", type=Path)
    args = parser.parse_args()
    args.master_dir.mkdir(parents=True, exist_ok=True)
    args.bundle_dir.mkdir(parents=True, exist_ok=True)
    entries: list[dict] = []

    for instrument_id, source_info in SOURCES.items():
        source = Path(source_info["source"])
        master = args.master_dir / f"{instrument_id}.wav"
        bundle = args.bundle_dir / f"{instrument_id}.wav"
        fade_out_start = max(float(source_info["duration"]) - 0.10, 0)
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-ss",
                str(source_info["start"]),
                "-t",
                str(source_info["duration"]),
                "-i",
                str(source),
                "-ac",
                "1",
                "-ar",
                "44100",
                "-af",
                f"loudnorm=I=-18:TP=-1.5:LRA=7,afade=t=in:st=0:d=0.02,afade=t=out:st={fade_out_start}:d=0.10",
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
                "instrument_name_zh": source_info["name_zh"],
                "source_title": source_info["title"],
                "source_url": source_info["source_url"],
                "author": source_info["author"],
                "license": source_info["license"],
                "license_url": source_info["license_url"],
                "source_note": source_info["source_note"],
                "source_file": str(source),
                "source_sha256": sha256(source),
                "selected_excerpt": {
                    "start_seconds": source_info["start"],
                    "duration_seconds": source_info["duration"],
                },
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
                    "selected a short representative excerpt",
                    "converted to mono 44100 Hz 16-bit PCM WAV",
                    "normalized to -18 LUFS / -1.5 dBTP target",
                    "applied short start and end fades",
                ],
                "status": "approved_source_license_format",
                "source_identity_review": "source_page_instrument_label_verified",
            }
        )

    manifest = {
        "schema_version": 1,
        "policy_note": "All bundled sources identify a real instrument, permit commercial reuse, preserve attribution and source hashes, and are never AI, VST, sample-library, MIDI, or streaming extractions.",
        "entries": entries,
    }
    args.output_manifest.parent.mkdir(parents=True, exist_ok=True)
    args.output_manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Prepared {len(entries)} open-license WAV masters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
