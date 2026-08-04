#!/usr/bin/env python3
"""Extract a small, auditable sample set from Zenodo record 8012071.

The source archive is 5.6 GB, so this tool exposes it to ``zipfile`` through
HTTP range requests and downloads only the central directory and selected MP3
members. It intentionally does not select a production master; listening and
signal-quality review happen after extraction.
"""

from __future__ import annotations

import argparse
import io
import json
import ssl
import urllib.request
import zipfile
from dataclasses import asdict, dataclass
from pathlib import Path


SOURCE_URL = "https://zenodo.org/records/8012071/files/FolkMusic.zip?download=1"
SOURCE_RECORD = "https://zenodo.org/records/8012071"
USER_AGENT = "GuoYuePracticeApp/1.0 (jushiung@gmail.com)"


class HTTPRangeReader(io.RawIOBase):
    """Seekable read-only stream backed by HTTP byte range requests."""

    def __init__(self, url: str) -> None:
        self.url = url
        self.position = 0
        self.context = ssl.create_default_context(cafile="/etc/ssl/cert.pem")
        request = urllib.request.Request(
            url,
            headers={"Range": "bytes=0-0", "User-Agent": USER_AGENT},
        )
        with urllib.request.urlopen(request, context=self.context) as response:
            content_range = response.headers.get("Content-Range", "")
            if "/" not in content_range:
                raise RuntimeError("Source server did not return Content-Range")
            self.length = int(content_range.rsplit("/", 1)[1])

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self.position

    def seek(self, offset: int, whence: int = io.SEEK_SET) -> int:
        if whence == io.SEEK_SET:
            target = offset
        elif whence == io.SEEK_CUR:
            target = self.position + offset
        elif whence == io.SEEK_END:
            target = self.length + offset
        else:
            raise ValueError(f"Unsupported whence: {whence}")
        if target < 0:
            raise ValueError("Negative seek position")
        self.position = min(target, self.length)
        return self.position

    def read(self, size: int = -1) -> bytes:
        if self.position >= self.length:
            return b""
        if size is None or size < 0:
            end = self.length - 1
        else:
            end = min(self.position + size - 1, self.length - 1)
        if end < self.position:
            return b""

        request = urllib.request.Request(
            self.url,
            headers={
                "Range": f"bytes={self.position}-{end}",
                "User-Agent": USER_AGENT,
            },
        )
        with urllib.request.urlopen(request, context=self.context) as response:
            payload = response.read()
        self.position += len(payload)
        return payload


@dataclass(frozen=True)
class ExtractedSample:
    instrument_id: str
    dataset_folder: str
    archive_member: str
    compressed_size: int
    uncompressed_size: int
    local_path: str


def parse_mapping(value: str) -> tuple[str, str]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("Expected APP_ID=DATASET_FOLDER")
    app_id, dataset_folder = value.split("=", 1)
    if not app_id or not dataset_folder:
        raise argparse.ArgumentTypeError("Expected APP_ID=DATASET_FOLDER")
    return app_id, dataset_folder


def evenly_spaced(items: list[zipfile.ZipInfo], count: int) -> list[zipfile.ZipInfo]:
    if len(items) <= count:
        return items
    if count == 1:
        return [items[len(items) // 2]]
    indices = [round(index * (len(items) - 1) / (count - 1)) for index in range(count)]
    return [items[index] for index in indices]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--instrument",
        action="append",
        type=parse_mapping,
        required=True,
        help="Repeatable APP_ID=DATASET_FOLDER mapping, for example xiao=dongxiao",
    )
    parser.add_argument("--per-instrument", type=int, default=5)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()

    if args.per_instrument < 1:
        parser.error("--per-instrument must be at least 1")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    extracted: list[ExtractedSample] = []

    with zipfile.ZipFile(HTTPRangeReader(SOURCE_URL)) as archive:
        all_members = archive.infolist()
        for instrument_id, dataset_folder in args.instrument:
            prefix = f"{dataset_folder}/"
            candidates = sorted(
                (
                    item
                    for item in all_members
                    if item.filename.startswith(prefix)
                    and item.filename.lower().endswith(".mp3")
                ),
                key=lambda item: item.filename,
            )
            if not candidates:
                raise RuntimeError(f"No MP3 members found under {prefix}")

            destination_dir = args.output_dir / instrument_id
            destination_dir.mkdir(parents=True, exist_ok=True)
            for item in evenly_spaced(candidates, args.per_instrument):
                destination = destination_dir / Path(item.filename).name
                with archive.open(item) as source, destination.open("wb") as target:
                    while chunk := source.read(1024 * 256):
                        target.write(chunk)
                extracted.append(
                    ExtractedSample(
                        instrument_id=instrument_id,
                        dataset_folder=dataset_folder,
                        archive_member=item.filename,
                        compressed_size=item.compress_size,
                        uncompressed_size=item.file_size,
                        local_path=str(destination),
                    )
                )

    manifest = {
        "source_record": SOURCE_RECORD,
        "source_archive": SOURCE_URL,
        "source_archive_md5": "2cc1146dbf48dd014a0d698dd743b71d",
        "license": "CC BY 4.0",
        "samples": [asdict(item) for item in extracted],
    }
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Extracted {len(extracted)} samples to {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
