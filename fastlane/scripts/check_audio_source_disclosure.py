#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "manifests"
    / "verified_audio_sources.json"
)
CATALOG = ROOT / "GuoYueZhiPu" / "Models" / "AssetCredits.swift"
TONE_PLAYER = ROOT / "GuoYueZhiPu" / "Services" / "TonePlayer.swift"
DATA_EXPORT = ROOT / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
PREMIUM_VIEW = ROOT / "GuoYueZhiPu" / "Views" / "PremiumView.swift"
INSTRUMENTS_VIEW = ROOT / "GuoYueZhiPu" / "Views" / "InstrumentsView.swift"
CREDITS_VIEW = ROOT / "GuoYueZhiPu" / "Views" / "AssetCreditsView.swift"
PBXPROJ = ROOT / "GuoYueZhiPu.xcodeproj" / "project.pbxproj"


def main() -> int:
    failures = []

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    catalog = CATALOG.read_text(encoding="utf-8")
    tone_player = TONE_PLAYER.read_text(encoding="utf-8")
    data_export = DATA_EXPORT.read_text(encoding="utf-8")
    premium_view = PREMIUM_VIEW.read_text(encoding="utf-8")
    instruments_view = INSTRUMENTS_VIEW.read_text(encoding="utf-8")
    credits_view = CREDITS_VIEW.read_text(encoding="utf-8")
    pbxproj = PBXPROJ.read_text(encoding="utf-8")

    approved = [
        item
        for item in manifest.get("approved", [])
        if item.get("status") == "approved"
    ]
    candidates = [
        item
        for item in manifest.get("candidates", [])
        if item.get("status") == "candidate"
    ]
    external_references = [
        item
        for item in manifest.get("external_references", [])
        if item.get("status") == "external_reference_not_bundled"
    ]

    for item in approved:
        values = [
            item.get("instrument_id", ""),
            item.get("author", ""),
            item.get("license", ""),
            item.get("sha256", ""),
        ]
        if not item.get("source_title", "").startswith("China traditional music instrument dataset"):
            values.append(item.get("source_title", ""))
        for value in values:
            if value and value not in catalog:
                failures.append(f"approved source missing from AssetCredits.swift: {value}")

    candidate_ids = {"pipa", "suona", "zhongruan", "banhu"}
    for item in candidates:
        if item.get("instrument_id") not in candidate_ids:
            continue
        for value in [
            item.get("instrument_id", ""),
            item.get("source_title", ""),
            item.get("author", ""),
            item.get("license", ""),
        ]:
            if value and value not in catalog:
                failures.append(f"candidate source missing from AssetCredits.swift: {value}")

    for item in external_references:
        for value in [item.get("instrument_id", ""), item.get("source_url", "")]:
            if value and value not in catalog:
                failures.append(
                    f"external real-instrument reference missing from AssetCredits.swift: {value}"
                )
        if item.get("bundled") is not False or item.get("quiz_eligible") is not False:
            failures.append(
                f"{item.get('instrument_id')}: external reference must be unbundled and excluded from quizzes"
            )

    required_tone_tokens = [
        "AudioSourceCatalog.approvedSource",
        "暫不播放舊版合成音檔",
    ]
    for token in required_tone_tokens:
        if token not in tone_player:
            failures.append(f"TonePlayer.swift missing approved-audio guard token: {token}")

    for token in [
        "AssetCreditsView()",
        "查看實拍、音源來源與授權",
        "AudioSourceDisclosureCard",
        "實器錄音待取得授權",
        "試聽只播放已確認來源",
        "不以 AI 圖、相似樂器或合成音替代",
        "ExternalInstrumentDemonstrationCatalog",
        "開啟原站實器示範",
        "原站實器示範（未包入 App）",
    ]:
        if token not in (premium_view + instruments_view + credits_view + catalog):
            failures.append(f"audio source disclosure UI token missing: {token}")

    for token in [
        "AssetCredits.swift in Sources",
        "AssetCreditsView.swift in Sources",
    ]:
        if token not in pbxproj:
            failures.append(f"Xcode project missing audio disclosure source: {token}")

    stale_claims = [
        "No third-party media is bundled",
        "不包含第三方授權圖片或第三方音訊",
        "第三方媒體: None",
    ]
    for claim in stale_claims:
        if claim in data_export + catalog + premium_view + instruments_view:
            failures.append(f"stale no-third-party-media claim remains: {claim}")

    print(
        "Audio source disclosure: "
        + f"{len(approved)} approved source(s), {len(external_references)} external reference(s), "
        + f"{len(candidates)} candidate source(s)"
    )

    if failures:
        print("\nAudio source disclosure check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Audio source disclosure check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
