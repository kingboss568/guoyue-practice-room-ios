#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PRODUCTS = ROOT / "fastlane" / "iap" / "products.json"
PAYWALL = ROOT / "fastlane" / "iap" / "paywall_review_manifest.json"
ASC_EVIDENCE = ROOT / "fastlane" / "iap" / "asc_iap_verification.json"
PREMIUM_STORE = ROOT / "GuoYueZhiPu" / "Services" / "PremiumStore.swift"
PREMIUM_VIEW = ROOT / "GuoYueZhiPu" / "Views" / "PremiumView.swift"
SCREENSHOTS = ROOT / "fastlane" / "screenshots" / "zh-Hant" / "screenshot_manifest.json"
AUDIO_MANIFEST = ROOT / "Design" / "Source" / "VerifiedAudio" / "manifests" / "verified_audio_sources.json"
ORCHESTRA_DATA = ROOT / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
FULL_OFFLINE_AUDIO_PHRASE = "完整離線聲音包"
TEXT_DOCS = [
    ROOT / "Docs" / "IAP-Setup.md",
    ROOT / "Docs" / "AppStoreConnectFields.zh-Hant.md",
    ROOT / "Docs" / "ReviewNotes.zh-Hant.md",
    ROOT / "fastlane" / "metadata" / "zh-Hant" / "review_information" / "notes.txt",
]
OVERCLAIM_PHRASES = [
    "每件樂器的離線音色素材",
    "試聽離線聲音",
    "進階音色訓練提示",
    "已核准實器音色訓練提示",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    failures = []
    warnings = []

    products = load_json(PRODUCTS)
    paywall = load_json(PAYWALL)
    asc_evidence = load_json(ASC_EVIDENCE) if ASC_EVIDENCE.exists() else None
    screenshot_manifest = load_json(SCREENSHOTS)
    audio_manifest = load_json(AUDIO_MANIFEST)
    orchestra_data = load_json(ORCHESTRA_DATA)
    store_source = PREMIUM_STORE.read_text(encoding="utf-8")
    view_source = PREMIUM_VIEW.read_text(encoding="utf-8")

    product = products.get("products", [{}])[0]
    product_id = product.get("product_id")
    if paywall.get("product_id") != product_id:
        failures.append("paywall_review_manifest product_id must match fastlane/iap/products.json")
    if products.get("bundle_id") != paywall.get("bundle_id"):
        failures.append("paywall_review_manifest bundle_id must match products.json")

    if product_id not in store_source:
        failures.append(f"{product_id} missing from PremiumStore.swift")
    if "PremiumStore.proProductID" not in view_source:
        failures.append("PremiumView.swift must display the centralized PremiumStore.proProductID")

    expected = paywall.get("expected_paywall_text", {})
    for text_key in ["display_name", "description"]:
        expected_text = expected.get(text_key, "")
        if expected_text and expected_text not in json.dumps(product.get("localizations", {}), ensure_ascii=False):
            failures.append(f"expected paywall {text_key} does not match products.json localization")
    for text_key in ["purchase_label", "restore_label", "missing_product_state"]:
        expected_text = expected.get(text_key, "")
        if expected_text and expected_text not in (store_source + view_source):
            failures.append(f"expected paywall text missing from Swift sources: {text_key}")

    approved_audio_ids = {
        item.get("instrument_id")
        for item in audio_manifest.get("approved", [])
        if item.get("status") == "approved"
    }
    instrument_ids = {item.get("id") for item in orchestra_data.get("instruments", [])}
    audio_gate_passed = bool(instrument_ids) and approved_audio_ids == instrument_ids
    full_offline_claim_text = (
        json.dumps(product.get("localizations", {}), ensure_ascii=False)
        + json.dumps(expected, ensure_ascii=False)
        + view_source
    )
    has_full_offline_claim = FULL_OFFLINE_AUDIO_PHRASE in full_offline_claim_text

    required_swift_tokens = [
        "purchasePro()",
        "restorePurchases()",
        "loadProducts()",
        "isProProductLoaded",
        "productAvailabilityText",
        "PremiumStore.proProductID",
        "Pro 實際解鎖內容",
        "每種樂器免費 5 題",
        "未核准樂器不會以假音色補位",
        "23 種樂器各 50 題",
        "230 題基礎知識",
        "不把候選或舊版合成素材包裝成正式內容",
    ]
    for token in required_swift_tokens:
        if token not in (store_source + view_source):
            failures.append(f"StoreKit paywall token missing: {token}")

    stale_claims = [
        "原創生成的樂器插圖",
        "原創生成，不包含第三方授權圖片或第三方音訊",
        "Original generated WAV",
        "Original generated image",
        "第三方媒體: None",
        "Third-party media: None bundled",
    ]
    for doc in TEXT_DOCS:
        text = doc.read_text(encoding="utf-8")
        for claim in stale_claims:
            if claim in text:
                failures.append(f"stale asset claim in {doc.relative_to(ROOT)}: {claim}")
        for phrase in OVERCLAIM_PHRASES:
            if phrase in text:
                failures.append(f"overclaimed unfinished audio in {doc.relative_to(ROOT)}: {phrase}")
        if product_id not in text:
            failures.append(f"{product_id} missing from {doc.relative_to(ROOT)}")

    roles_by_device = {}
    for item in screenshot_manifest.get("screenshots", []):
        roles_by_device.setdefault(item.get("device"), set()).add(item.get("screen_role"))
    for device, roles in [("iphone69", {"pro", "payment"}), ("ipad13", {"pro", "payment"})]:
        missing = roles - roles_by_device.get(device, set())
        if missing:
            failures.append(f"{device}: screenshot manifest missing paywall roles: {', '.join(sorted(missing))}")

    requirements = paywall.get("review_requirements", {})
    if has_full_offline_claim and not audio_gate_passed:
        missing_audio = sorted(instrument_ids - approved_audio_ids)
        message = (
            "paywall/IAP claims full offline audio pack before audio gate passes: "
            + f"{len(approved_audio_ids)}/{len(instrument_ids)} approved, "
            + "missing "
            + ", ".join(missing_audio[:8])
            + (" ..." if len(missing_audio) > 8 else "")
        )
        if requirements.get("paywall_does_not_claim_unfinished_audio_pack") is True:
            failures.append(
                "paywall_does_not_claim_unfinished_audio_pack cannot be true while "
                + message
            )
        if requirements.get("full_offline_audio_pack_claim_waits_for_audio_gate") is True:
            failures.append(
                "full_offline_audio_pack_claim_waits_for_audio_gate cannot be true while "
                + message
            )
        warnings.append(message)
    elif has_full_offline_claim and audio_gate_passed:
        if requirements.get("full_offline_audio_pack_claim_waits_for_audio_gate") is not True:
            warnings.append("full offline audio pack claim is now eligible after audio gate; update review manifest")

    if asc_evidence:
        checks = asc_evidence.get("checks", {})
        evidence_requirements = {
            "app_store_connect_product_created": "product_created",
            "price_tier_confirmed": "price_schedule_present",
            "zh_hant_localization_confirmed": "zh_hant_localization_matches",
            "iap_attached_to_app_version": "iap_attached_to_app_version",
        }
        for requirement, evidence_key in evidence_requirements.items():
            if requirements.get(requirement) is True and checks.get(evidence_key) is not True:
                failures.append(
                    f"{requirement} is true but ASC evidence {evidence_key} is not true"
                )

        if checks.get("zh_hant_localization_matches") is not True:
            actual_localizations = asc_evidence.get("localizations", [])
            if actual_localizations:
                zh_hant = next(
                    (item for item in actual_localizations if item.get("locale") == "zh-Hant"),
                    actual_localizations[0],
                )
                warnings.append(
                    "ASC zh-Hant localization mismatch: "
                    + f"name={zh_hant.get('name')!r}, description={zh_hant.get('description')!r}"
                )

    pending_requirements = [
        key
        for key, value in requirements.items()
        if value is not True
    ]
    print(f"StoreKit paywall manifest: product {product_id}")
    print(f"StoreKit paywall pending review requirements: {len(pending_requirements)}")

    if pending_requirements:
        message = "Pending StoreKit/App Review requirements: " + ", ".join(pending_requirements)
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    if paywall.get("status") != "ready_for_review":
        message = f"paywall_review_manifest status is {paywall.get('status')}; expected ready_for_review"
        if args.strict:
            failures.append(message)
        else:
            warnings.append(message)

    for warning in warnings:
        print(f"WARNING: {warning}")

    if failures:
        print("\nStoreKit paywall check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("StoreKit paywall check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
