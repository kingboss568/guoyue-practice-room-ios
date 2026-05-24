#!/usr/bin/env python3
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "fastlane" / "iap" / "products.json"
PREMIUM_STORE = ROOT / "GuoYueZhiPu" / "Services" / "PremiumStore.swift"
DOCS = [
    ROOT / "Docs" / "IAP-Setup.md",
    ROOT / "Docs" / "AppStoreConnectFields.zh-Hant.md",
    ROOT / "Docs" / "ReviewNotes.zh-Hant.md",
]


def main() -> int:
    failures = []
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))

    if data.get("bundle_id") != "com.yuhsiangjiang.GuoYueZhiPu":
        failures.append("bundle_id mismatch in fastlane/iap/products.json")
    if data.get("team_id") != "7H7ZUG2WX8":
        failures.append("team_id mismatch in fastlane/iap/products.json")

    product_ids = [product.get("product_id") for product in data.get("products", [])]
    if product_ids != ["com.yuhsiangjiang.GuoYueZhiPu.pro"]:
        failures.append("expected exactly one non-consumable Pro product")

    product = data["products"][0]
    if product.get("type") != "non_consumable":
        failures.append("Pro product must be non_consumable")
    if not product.get("cleared_for_sale"):
        failures.append("Pro product must be cleared_for_sale in manifest")

    premium_store = PREMIUM_STORE.read_text(encoding="utf-8")
    for product_id in product_ids:
        if product_id not in premium_store:
            failures.append(f"{product_id} missing from PremiumStore.swift")
        for doc in DOCS:
            if product_id not in doc.read_text(encoding="utf-8"):
                failures.append(f"{product_id} missing from {doc.relative_to(ROOT)}")

    if failures:
        print("IAP manifest check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("IAP manifest OK: com.yuhsiangjiang.GuoYueZhiPu.pro")
    return 0


if __name__ == "__main__":
    sys.exit(main())
