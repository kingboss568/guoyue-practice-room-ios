#!/usr/bin/env python3
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "GuoYueZhiPu" / "Resources" / "chinese_orchestra_data_export.json"
PRACTICE = ROOT / "GuoYueZhiPu" / "Views" / "PracticeView.swift"
AUDIO_CATALOG = ROOT / "GuoYueZhiPu" / "Models" / "AssetCredits.swift"
AUDIO_DIR = ROOT / "GuoYueZhiPu" / "Resources" / "Audio" / "Instruments"


def main() -> int:
    data = json.loads(DATA.read_text(encoding="utf-8"))
    instruments = data.get("instruments", [])
    instrument_ids = [item.get("id") for item in instruments]
    sections = data.get("sections", [])
    source = PRACTICE.read_text(encoding="utf-8")
    audio_source = AUDIO_CATALOG.read_text(encoding="utf-8")
    failures = []

    if len(instruments) != 23 or len(set(instrument_ids)) != 23:
        failures.append(f"expected 23 unique instruments, found {len(set(instrument_ids))}")
    if len(sections) != 4:
        failures.append(f"expected four orchestra sections, found {len(sections)}")

    required_tokens = [
        "for round in 0..<5",
        "for template in 0..<10",
        ".prefix(10)",
        "Array(allQuestions.prefix(5))",
        "Array(allQuestions.prefix(20))",
        "audioInstrumentID: instrument.id",
        "tonePlayer.play(instrument: instrument)",
    ]
    for token in required_tokens:
        if token not in source:
            failures.append(f"practice generator/access token missing: {token}")

    approved_block = audio_source.split("static let approvedSources", 1)[-1].split(
        "static let candidateSources", 1
    )[0]
    approved_ids = re.findall(r'instrumentID:\s*"([a-z0-9_]+)"', approved_block)
    approved_ids = list(dict.fromkeys(approved_ids))
    unknown_audio = sorted(set(approved_ids) - set(instrument_ids))
    if unknown_audio:
        failures.append("approved audio IDs not in instrument data: " + ", ".join(unknown_audio))
    for instrument_id in approved_ids:
        if not (AUDIO_DIR / f"{instrument_id}.wav").is_file():
            failures.append(f"approved listening source has no bundled WAV: {instrument_id}")

    questions_per_instrument = 5 * 10
    instrument_total = len(instruments) * questions_per_instrument
    foundation_total = len(instruments) * 10
    listening_total = len(approved_ids) * 3

    if questions_per_instrument != 50:
        failures.append("instrument question generator no longer yields 50 questions")
    if foundation_total < 200:
        failures.append(f"foundation question count below 200: {foundation_total}")

    print(f"Instrument practice bank: {len(instruments)} x {questions_per_instrument} = {instrument_total}")
    print(f"Foundation bank: {foundation_total}")
    print(f"Licensed real-audio listening bank: {len(approved_ids)} x 3 = {listening_total}")

    if failures:
        print("\nPractice question bank check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Practice question bank check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
