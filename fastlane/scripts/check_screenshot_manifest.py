#!/usr/bin/env python3
import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCREENSHOTS_DIR = ROOT / "fastlane" / "screenshots" / "zh-Hant"
MANIFEST = SCREENSHOTS_DIR / "screenshot_manifest.json"
CURRENT_STATUS = "current_after_redesign"
EXPECTED_DEVICES = {
    "iphone69": (1320, 2868),
    "ipad13": (2064, 2752),
}


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    failures = []
    warnings = []

    if not MANIFEST.exists():
        print(f"Screenshot manifest missing: {MANIFEST.relative_to(ROOT)}")
        return 1

    with MANIFEST.open(encoding="utf-8") as f:
        manifest = json.load(f)

    required_roles = set(manifest.get("required_screen_roles", []))
    required_devices = {
        item.get("device"): item
        for item in manifest.get("required_devices", [])
        if item.get("device")
    }
    screenshots = manifest.get("screenshots", [])
    by_device = defaultdict(list)

    if manifest.get("locale") != "zh-Hant":
        failures.append("manifest locale must be zh-Hant")
    if manifest.get("app") != "GuoYueZhiPu":
        failures.append("manifest app must be GuoYueZhiPu")

    for device, spec in EXPECTED_DEVICES.items():
        requirement = required_devices.get(device)
        if not requirement:
            failures.append(f"manifest missing required device: {device}")
            continue
        if tuple(requirement.get("required_size", [])) != spec:
            failures.append(f"{device}: required_size must be {spec[0]}x{spec[1]}")
        if int(requirement.get("required_count", 0)) < 6:
            failures.append(f"{device}: required_count must be at least 6")

    for item in screenshots:
        filename = item.get("file", "")
        device = item.get("device", "")
        role = item.get("screen_role", "")
        status = item.get("status", "")
        expected_sha = item.get("sha256", "")
        path = SCREENSHOTS_DIR / filename

        if device not in EXPECTED_DEVICES:
            failures.append(f"{filename}: unknown device {device}")
            continue
        if role not in required_roles:
            failures.append(f"{filename}: screen_role {role} is not in required_screen_roles")
        if not path.exists():
            failures.append(f"{filename}: file is missing")
            continue
        if expected_sha and digest(path) != expected_sha:
            failures.append(f"{filename}: sha256 does not match manifest")
        if status != CURRENT_STATUS:
            message = f"{filename}: screenshot status is {status}; recapture and mark {CURRENT_STATUS}"
            if args.strict:
                failures.append(message)
            else:
                warnings.append(message)

        by_device[device].append(item)

    for device in EXPECTED_DEVICES:
        items = by_device.get(device, [])
        roles = {item.get("screen_role") for item in items}
        missing_roles = sorted(required_roles - roles)
        payment_count = sum(1 for item in items if item.get("contains_payment_or_iap") is True)

        print(f"{device}: {len(items)} screenshot manifest item(s), payment/IAP items {payment_count}")
        if len(items) < 6:
            failures.append(f"{device}: manifest lists only {len(items)} screenshots")
        if missing_roles:
            failures.append(f"{device}: missing screen roles: {', '.join(missing_roles)}")
        if payment_count < 1:
            failures.append(f"{device}: at least one screenshot must show payment or IAP")

    if not manifest.get("generated_after_asset_gate"):
        message = "manifest generated_after_asset_gate is false; recapture after verified audio and artwork gates pass"
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)
    if not manifest.get("generated_after_paywall_redesign"):
        message = "manifest generated_after_paywall_redesign is false; recapture after current StoreKit paywall is built"
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)
    if manifest.get("status") != CURRENT_STATUS:
        message = f"manifest status is {manifest.get('status')}; expected {CURRENT_STATUS}"
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nScreenshot manifest check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Screenshot manifest OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
