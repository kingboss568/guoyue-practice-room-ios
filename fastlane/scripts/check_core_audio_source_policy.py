#!/usr/bin/env python3
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
POLICY_DOC = ROOT / "Docs" / "AssetLicenses" / "CoreAudioSourcePolicy.zh-Hant.md"
MANIFEST = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "manifests"
    / "verified_audio_sources.json"
)
TRACKER = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "audio_procurement_tracker.json"
)
CATALOG = ROOT / "GuoYueZhiPu" / "Models" / "AssetCredits.swift"

REQUIRED_BANNED_SOURCES = {
    "VST or sample library playback",
    "AI-generated instrument tone",
    "Suno/Udio/generative music output",
    "YouTube/CD/streaming extraction",
    "unknown performer or unknown license",
}

POLICY_TOKENS = [
    "Suno/Udio/generative music output",
    "AI-generated instrument tone",
    "VST or sample library playback",
    "YouTube/CD/streaming extraction",
    "TonePlayer",
]

APPROVED_REQUIRED_FIELDS = [
    "instrument_id",
    "source_title",
    "source_url",
    "author",
    "license",
    "local_wav_path",
    "bundle_wav_path",
    "sha256",
    "status",
]

BANNED_APPROVED_PATTERNS = [
    (r"\bsuno\b", "suno"),
    (r"\budio\b", "udio"),
    (r"\bmusicgen\b", "musicgen"),
    (r"\bstable audio\b", "stable audio"),
    (r"\bai-generated\b", "ai-generated"),
    (r"\bai generated\b", "ai generated"),
    (r"\bgenerative music\b", "generative music"),
    (r"\bvst\b", "vst"),
    (r"\bsample library\b", "sample library"),
    (r"\byoutube\b", "youtube"),
    (r"\bstreaming extraction\b", "streaming extraction"),
    (r"\bcd extraction\b", "cd extraction"),
]


def searchable_text(item):
    values = []
    for value in item.values():
        if isinstance(value, str):
            values.append(value)
        elif isinstance(value, list):
            values.extend(str(part) for part in value)
    return " ".join(values).lower()


def main():
    failures = []

    if not POLICY_DOC.exists():
        failures.append("Missing core audio source policy doc")
        policy_text = ""
    else:
        policy_text = POLICY_DOC.read_text(encoding="utf-8")

    for token in POLICY_TOKENS:
        if token not in policy_text:
            failures.append(f"Core audio source policy missing token: {token}")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    tracker = json.loads(TRACKER.read_text(encoding="utf-8"))
    catalog = CATALOG.read_text(encoding="utf-8")

    not_allowed = set(tracker.get("global_requirements", {}).get("not_allowed", []))
    missing_bans = sorted(REQUIRED_BANNED_SOURCES - not_allowed)
    if missing_bans:
        failures.append("Audio procurement tracker missing banned source types: " + ", ".join(missing_bans))

    approved = [
        item
        for item in manifest.get("approved", [])
        if item.get("status") == "approved"
    ]
    rejected = [
        item
        for item in manifest.get("candidates", [])
        if item.get("status") == "rejected"
    ]

    for item in approved:
        instrument_id = item.get("instrument_id", "unknown")
        for field in APPROVED_REQUIRED_FIELDS:
            if not str(item.get(field, "")).strip():
                failures.append(f"{instrument_id}: approved manifest field {field} is required")
        text = searchable_text(item)
        banned_hits = [
            label
            for pattern, label in BANNED_APPROVED_PATTERNS
            if re.search(pattern, text)
        ]
        if banned_hits:
            failures.append(f"{instrument_id}: approved source contains banned source token(s): {', '.join(banned_hits)}")

    for item in rejected:
        source_title = item.get("source_title", "")
        instrument_id = item.get("instrument_id", "unknown")
        if not source_title:
            failures.append(f"{instrument_id}: rejected candidate must keep source_title for audit trail")
            continue
        if source_title in catalog:
            failures.append(f"{instrument_id}: rejected source is exposed in App asset catalog: {source_title}")
        if item.get("status") == "approved":
            failures.append(f"{instrument_id}: rejected source cannot be approved")

    print(
        "Core audio source policy: "
        + f"{len(approved)} approved source(s), {len(rejected)} rejected candidate(s), "
        + f"{len(not_allowed)} banned source rule(s)."
    )

    if failures:
        print("\nCore audio source policy check failed:")
        for failure in failures:
            print(f"- {failure}")
        raise SystemExit(1)

    print("Core audio source policy check passed.")


if __name__ == "__main__":
    main()
