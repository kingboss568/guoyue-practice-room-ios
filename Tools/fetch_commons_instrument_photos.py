#!/usr/bin/env python3
"""Download selected Wikimedia Commons instrument photos and record credits."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import ssl
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path


API_URL = "https://commons.wikimedia.org/w/api.php"
USER_AGENT = "GuoYuePracticeApp/1.0 (jushiung@gmail.com)"
SSL_CONTEXT = ssl.create_default_context(cafile="/etc/ssl/cert.pem")


def plain_text(value: str | None) -> str:
    if not value:
        return ""
    without_tags = re.sub(r"<[^>]+>", " ", value)
    return " ".join(html.unescape(without_tags).split())


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fetch_json(parameters: dict[str, str]) -> dict:
    query = urllib.parse.urlencode(parameters)
    request = urllib.request.Request(
        f"{API_URL}?{query}",
        headers={"User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(request, context=SSL_CONTEXT) as response:
        return json.load(response)


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, context=SSL_CONTEXT) as response, destination.open("wb") as output:
        while chunk := response.read(1024 * 256):
            output.write(chunk)


def process_photo(source: Path, destination: Path) -> None:
    temporary = destination.with_suffix(".working.jpg")
    subprocess.run(
        [
            "sips",
            "-s",
            "format",
            "jpeg",
            "-s",
            "formatOptions",
            "86",
            "-Z",
            "1000",
            str(source),
            "--out",
            str(temporary),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        [
            "sips",
            "-p",
            "1080",
            "1080",
            "--padColor",
            "F3EFE6",
            str(temporary),
            "--out",
            str(destination),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    temporary.unlink()


def metadata_value(metadata: dict, key: str) -> str:
    return plain_text(metadata.get(key, {}).get("value"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("selection", type=Path)
    parser.add_argument("originals_dir", type=Path)
    parser.add_argument("asset_catalog", type=Path)
    parser.add_argument("output_manifest", type=Path)
    args = parser.parse_args()

    selection = json.loads(args.selection.read_text(encoding="utf-8"))
    commons_selected = [
        item for item in selection["instruments"] if item.get("commons_title")
    ]
    external_selected = [
        item
        for item in selection["instruments"]
        if item.get("download_url") and not item.get("commons_title")
    ]
    pages: dict[str, dict] = {}
    if commons_selected:
        titles = "|".join(item["commons_title"] for item in commons_selected)
        response = fetch_json(
            {
                "action": "query",
                "titles": titles,
                "prop": "imageinfo",
                "iiprop": "url|mime|size|sha1|extmetadata",
                "iiurlwidth": "1600",
                "format": "json",
                "formatversion": "2",
            }
        )
        pages = {page["title"]: page for page in response["query"]["pages"]}
    args.originals_dir.mkdir(parents=True, exist_ok=True)
    results: list[dict[str, object]] = []

    for item in commons_selected:
        page = pages.get(item["commons_title"])
        if not page or page.get("missing"):
            raise RuntimeError(f"Commons file not found: {item['commons_title']}")
        image_info = page["imageinfo"][0]
        metadata = image_info.get("extmetadata", {})
        source_url = image_info.get("thumburl") or image_info["url"]
        extension = Path(urllib.parse.urlparse(source_url).path).suffix or ".jpg"
        original = args.originals_dir / f"{item['instrument_id']}{extension.lower()}"
        destination = (
            args.asset_catalog
            / f"instrument_{item['instrument_id']}.imageset"
            / f"instrument_{item['instrument_id']}.jpg"
        )
        download(source_url, original)
        process_photo(original, destination)
        results.append(
            {
                "instrument_id": item["instrument_id"],
                "name_zh": item["name_zh"],
                "commons_title": page["title"],
                "source_page": image_info.get("descriptionurl"),
                "download_url": source_url,
                "original_file_url": image_info.get("url"),
                "author": metadata_value(metadata, "Artist"),
                "credit": metadata_value(metadata, "Credit"),
                "description": metadata_value(metadata, "ImageDescription"),
                "date": metadata_value(metadata, "DateTimeOriginal")
                or metadata_value(metadata, "DateTime"),
                "license": metadata_value(metadata, "LicenseShortName"),
                "license_url": metadata_value(metadata, "LicenseUrl"),
                "copyrighted": metadata_value(metadata, "Copyrighted"),
                "source_dimensions": {
                    "width": image_info.get("width"),
                    "height": image_info.get("height"),
                },
                "commons_sha1": image_info.get("sha1"),
                "download_sha256": sha256(original),
                "app_asset_sha256": sha256(destination),
                "local_original": str(original),
                "app_asset": str(destination),
                "derivative_actions": [
                    "downloaded a 1600-pixel Wikimedia Commons preview",
                    "auto-oriented and converted to JPEG",
                    "resized to fit within 1000 pixels",
                    "padded to 1080 by 1080 without cropping",
                ],
                "status": "source_and_internal_visual_qc_complete_pending_professional_review",
            }
        )

    for item in external_selected:
        source_url = item["download_url"]
        extension = Path(urllib.parse.urlparse(source_url).path).suffix or ".jpg"
        original = args.originals_dir / f"{item['instrument_id']}{extension.lower()}"
        destination = (
            args.asset_catalog
            / f"instrument_{item['instrument_id']}.imageset"
            / f"instrument_{item['instrument_id']}.jpg"
        )
        download(source_url, original)
        process_photo(original, destination)
        results.append(
            {
                "instrument_id": item["instrument_id"],
                "name_zh": item["name_zh"],
                "commons_title": None,
                "source_provider": item.get("source_provider"),
                "openverse_id": item.get("openverse_id"),
                "source_page": item.get("source_page"),
                "download_url": source_url,
                "original_file_url": source_url,
                "author": item.get("author", ""),
                "credit": f'"{item.get("source_title", "Untitled")}" by {item.get("author", "Unknown")}',
                "description": item.get("description", item.get("source_title", "")),
                "date": item.get("date", ""),
                "license": item.get("license", ""),
                "license_url": item.get("license_url", ""),
                "copyrighted": "True",
                "source_dimensions": {
                    "width": item.get("source_width"),
                    "height": item.get("source_height"),
                },
                "download_sha256": sha256(original),
                "app_asset_sha256": sha256(destination),
                "local_original": str(original),
                "app_asset": str(destination),
                "derivative_actions": [
                    "downloaded the licensed source image from its stable URL",
                    "auto-oriented and converted to JPEG",
                    "resized to fit within 1000 pixels",
                    "padded to 1080 by 1080 without cropping",
                ],
                "status": item.get(
                    "status",
                    "source_and_internal_visual_qc_complete_pending_professional_review",
                ),
            }
        )

    blocked = [
        item
        for item in selection["instruments"]
        if str(item.get("status", "")).startswith("blocked_")
    ]
    output = {
        "schema_version": 1,
        "source": "Wikimedia Commons API and individually licensed external sources",
        "results": results,
        "blocked": blocked,
    }
    args.output_manifest.parent.mkdir(parents=True, exist_ok=True)
    args.output_manifest.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Downloaded and processed {len(results)} photos")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
