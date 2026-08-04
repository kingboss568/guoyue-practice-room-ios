#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_IDS = {"gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"}
CARDS = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "professional_visual_review_cards.json"
)
REFERENCES = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "artwork_reference_sources.json"
)
MORPHOLOGY = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "high_risk_artwork_morphology_specs.json"
)
DOC = ROOT / "Docs" / "InstrumentArtworkVisualReviewCards.zh-Hant.md"

REQUIRED_DOC_TOKENS = [
    "professional_visual_review_cards.json",
    "approval_drafts",
    "不看文字也能辨識",
    "嗩吶",
    "笙",
    "板胡",
    "二胡",
    "高胡",
    "中胡",
    "革胡",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def nonempty_list(value, minimum):
    return isinstance(value, list) and len([item for item in value if str(item).strip()]) >= minimum


def main() -> int:
    failures = []

    cards = load_json(CARDS)
    references = load_json(REFERENCES)
    morphology = load_json(MORPHOLOGY)
    doc_text = DOC.read_text(encoding="utf-8") if DOC.exists() else ""

    if cards.get("status") != "review_cards_current":
        failures.append("professional_visual_review_cards status must be review_cards_current")
    if set(cards.get("high_risk_instrument_ids", [])) != REQUIRED_IDS:
        failures.append("professional_visual_review_cards high_risk_instrument_ids mismatch")
    if "not approvals" not in str(cards.get("policy", "")):
        failures.append("professional_visual_review_cards policy must state cards are not approvals")
    if not nonempty_list(cards.get("shared_thumbnail_tests"), 4):
        failures.append("shared_thumbnail_tests must include at least four tests")

    reference_by_id = {item.get("instrument_id"): item for item in references.get("sources", [])}
    spec_by_id = {item.get("instrument_id"): item for item in morphology.get("specs", [])}
    card_by_id = {item.get("instrument_id"): item for item in cards.get("cards", [])}

    missing = sorted(REQUIRED_IDS - set(card_by_id))
    unknown = sorted(set(card_by_id) - REQUIRED_IDS)
    if missing:
        failures.append("visual review cards missing instruments: " + ", ".join(missing))
    if unknown:
        failures.append("visual review cards include unknown instruments: " + ", ".join(unknown))

    for instrument_id in sorted(REQUIRED_IDS):
        card = card_by_id.get(instrument_id)
        reference = reference_by_id.get(instrument_id)
        spec = spec_by_id.get(instrument_id)
        if not card or not reference or not spec:
            failures.append(f"{instrument_id}: card/reference/spec must all exist")
            continue

        if card.get("candidate_path") != spec.get("candidate_file"):
            failures.append(f"{instrument_id}: candidate_path must match morphology candidate_file")
        if not (ROOT / card.get("candidate_path", "")).exists():
            failures.append(f"{instrument_id}: candidate image missing")

        ref_urls = set(reference.get("reference_urls", []))
        card_urls = set(card.get("primary_reference_urls", []))
        if len(card_urls) < 2:
            failures.append(f"{instrument_id}: at least two primary_reference_urls required")
        if not card_urls.issubset(ref_urls):
            failures.append(f"{instrument_id}: primary_reference_urls must be listed in artwork_reference_sources")

        if not nonempty_list(card.get("source_backed_features"), 4):
            failures.append(f"{instrument_id}: source_backed_features must include at least four entries")
        if not nonempty_list(card.get("acceptance_tests"), 5):
            failures.append(f"{instrument_id}: acceptance_tests must include at least five entries")
        if not nonempty_list(card.get("rejection_tests"), 5):
            failures.append(f"{instrument_id}: rejection_tests must include at least five entries")
        if "?" not in str(card.get("reviewer_question", "")):
            failures.append(f"{instrument_id}: reviewer_question must be a question")

        must_show_blob = "\n".join(spec.get("must_show", [])).lower()
        accept_blob = "\n".join(card.get("acceptance_tests", [])).lower()
        for keyword in ["string", "body", "pipe", "reed", "bell", "wind", "wood", "bow"]:
            if keyword in must_show_blob and keyword not in accept_blob:
                failures.append(f"{instrument_id}: acceptance_tests missing spec keyword {keyword}")

        must_not_blob = "\n".join(spec.get("must_not_show", [])).lower()
        reject_blob = "\n".join(card.get("rejection_tests", [])).lower()
        for keyword in ["erhu", "trumpet", "panpipe", "violin", "cello", "gehu", "banhu"]:
            if keyword in must_not_blob and keyword not in reject_blob:
                failures.append(f"{instrument_id}: rejection_tests missing spec confusion {keyword}")

        draft = ROOT / "Design" / "Review" / "ArtworkCandidates" / "approval_drafts" / f"{instrument_id}.approval.draft.json"
        if not draft.exists():
            failures.append(f"{instrument_id}: approval draft missing")

    if not DOC.exists():
        failures.append("Missing InstrumentArtworkVisualReviewCards.zh-Hant.md")
    else:
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"InstrumentArtworkVisualReviewCards.zh-Hant.md missing token: {token}")

    print(f"High-risk artwork visual review cards: {len(card_by_id)}/{len(REQUIRED_IDS)} instrument(s)")

    if failures:
        print("\nHigh-risk artwork visual review card check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("High-risk artwork visual review card check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
