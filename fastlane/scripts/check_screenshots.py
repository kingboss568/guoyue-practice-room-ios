#!/usr/bin/env python3
import argparse
import hashlib
from pathlib import Path
import sys

from PIL import Image, ImageStat


DEVICE_SPECS = {
    "iphone69": (1320, 2868),
    "ipad13": (2064, 2752),
}


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def variance_score(image: Image.Image) -> float:
    small = image.convert("L").resize((64, 64))
    return float(ImageStat.Stat(small).var[0])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("screenshots_dir", type=Path)
    parser.add_argument("--min-per-device", type=int, default=6)
    parser.add_argument("--allow-incomplete", action="store_true")
    args = parser.parse_args()

    if not args.screenshots_dir.is_dir():
        print(f"ERROR: screenshots directory missing: {args.screenshots_dir}")
        return 1

    grouped = {name: [] for name in DEVICE_SPECS}
    failures = []
    digests = {}

    for path in sorted(args.screenshots_dir.glob("*.png")):
        if path.name.startswith("._"):
            continue

        with Image.open(path) as image:
            size = image.size
            score = variance_score(image)

        device = next((name for name, spec in DEVICE_SPECS.items() if spec == size), None)
        if device is None:
            failures.append(f"{path.name}: unsupported screenshot size {size[0]}x{size[1]}")
            continue

        if score < 4.0:
            failures.append(f"{path.name}: image appears blank or near-blank (variance {score:.2f})")

        file_digest = digest(path)
        if file_digest in digests:
            failures.append(f"{path.name}: duplicate image content with {digests[file_digest]}")
        else:
            digests[file_digest] = path.name
        grouped[device].append(path.name)

    for device, files in grouped.items():
        count = len(files)
        spec = DEVICE_SPECS[device]
        print(f"{device}: {count} screenshot(s), expected >= {args.min_per_device}, size {spec[0]}x{spec[1]}")
        for name in files:
            print(f"  - {name}")
        if count < args.min_per_device:
            message = f"{device}: only {count} screenshot(s); add {args.min_per_device - count} more"
            if args.allow_incomplete:
                print(f"WARNING: {message}")
            else:
                failures.append(message)

    if failures:
        print("\nScreenshot check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
