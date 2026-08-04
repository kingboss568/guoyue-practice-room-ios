#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "manifests"
    / "verified_audio_sources.json"
)
TRACKER_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "audio_procurement_tracker.json"
)
SURVEY_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "open_audio_source_survey.json"
)
DOC_PATH = ROOT / "Docs" / "AssetLicenses" / "OpenAudioSourceSurvey.zh-Hant.md"

ALLOWED_DECISIONS = {
    "candidate_needs_review",
    "commission_required",
    "rejected_source_only",
    "approved_source_missing",
}

REQUIRED_BANNED_CATEGORIES = {
    "Suno/Udio/generative music output",
    "AI-generated instrument tone",
    "VST or sample library playback",
    "YouTube/CD/streaming extraction",
    "Pixabay/generic royalty-free background music without verifiable instrument stem",
}

REQUIRED_DOC_TOKENS = [
    "Suno",
    "VST",
    "YouTube",
    "Pixabay",
    "commission_required",
    "candidate_needs_review",
    "Commons API",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    failures = []

    manifest = load_json(MANIFEST_PATH)
    tracker = load_json(TRACKER_PATH)
    survey = load_json(SURVEY_PATH)
    doc_text = DOC_PATH.read_text(encoding="utf-8") if DOC_PATH.exists() else ""

    if survey.get("status") != "survey_current":
        failures.append("open audio source survey status must be survey_current")

    latest_search = survey.get("latest_search_round", {})
    if latest_search.get("new_candidate_count") != 0:
        failures.append("latest_search_round new_candidate_count must stay 0 unless candidates are added to manifest")
    if latest_search.get("eligible_new_approved_source_count") != 0:
        failures.append("latest_search_round cannot directly approve sources")
    if len(latest_search.get("commons_api_terms", [])) < 8:
        failures.append("latest_search_round must document Commons API terms")
    if "commission_required" not in str(latest_search.get("decision", "")):
        failures.append("latest_search_round decision must keep missing sources commission_required")

    open_ids = set(manifest.get("open_instrument_ids", []))
    survey_open_ids = set(survey.get("open_instrument_ids", []))
    if survey_open_ids != open_ids:
        failures.append(
            "open audio source survey open_instrument_ids mismatch: "
            + f"got {sorted(survey_open_ids)} expected {sorted(open_ids)}"
        )

    banned = set(survey.get("banned_source_categories", []))
    missing_bans = sorted(REQUIRED_BANNED_CATEGORIES - banned)
    if missing_bans:
        failures.append("open audio source survey missing banned categories: " + ", ".join(missing_bans))

    tracker_by_id = {
        item.get("instrument_id"): item
        for item in tracker.get("items", [])
    }
    manifest_candidate_ids = {
        item.get("instrument_id")
        for item in manifest.get("candidates", [])
        if item.get("status") == "candidate"
    }

    decisions = survey.get("instrument_decisions", [])
    decision_by_id = {item.get("instrument_id"): item for item in decisions}
    missing_decisions = sorted(open_ids - set(decision_by_id))
    extra_decisions = sorted(set(decision_by_id) - open_ids)
    if missing_decisions:
        failures.append("open audio source survey missing decisions: " + ", ".join(missing_decisions))
    if extra_decisions:
        failures.append("open audio source survey has non-open decisions: " + ", ".join(extra_decisions))

    for instrument_id in sorted(open_ids):
        item = decision_by_id.get(instrument_id)
        if not item:
            continue

        decision = item.get("decision")
        if decision not in ALLOWED_DECISIONS:
            failures.append(f"{instrument_id}: invalid survey decision {decision}")
        for field in ["name_zh", "rationale", "next_action"]:
            if not str(item.get(field, "")).strip():
                failures.append(f"{instrument_id}: survey field {field} is required")

        tracker_item = tracker_by_id.get(instrument_id)
        if not tracker_item:
            failures.append(f"{instrument_id}: procurement tracker item is missing")
            continue

        if decision == "commission_required" and tracker_item.get("status") != "procure_real_recording":
            failures.append(
                f"{instrument_id}: commission_required must match tracker status procure_real_recording"
            )
        if decision == "candidate_needs_review":
            tracker_status = str(tracker_item.get("status", ""))
            if not tracker_status.startswith("candidate_") and instrument_id not in manifest_candidate_ids:
                failures.append(
                    f"{instrument_id}: candidate_needs_review requires a candidate tracker or manifest entry"
                )
            if not item.get("candidate_urls"):
                failures.append(f"{instrument_id}: candidate_needs_review requires candidate_urls")

    source_families = survey.get("evaluated_source_families", [])
    if len(source_families) < 5:
        failures.append("open audio source survey must evaluate at least 5 source families")
    for family in source_families:
        decision = family.get("core_audio_decision")
        name = family.get("name", "unknown")
        if decision == "approved":
            failures.append(f"{name}: source family cannot be approved by survey")
        if decision not in {"candidate_only", "not_approved", "reference_only"}:
            failures.append(f"{name}: invalid core_audio_decision {decision}")
        if not str(family.get("reason", "")).strip():
            failures.append(f"{name}: source family reason is required")

    if not DOC_PATH.exists():
        failures.append("Missing OpenAudioSourceSurvey.zh-Hant.md")
    else:
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"OpenAudioSourceSurvey.zh-Hant.md missing token: {token}")

    print(
        "Open audio source survey: "
        + f"{len(decisions)}/{len(open_ids)} open instrument decision(s), "
        + f"{len(source_families)} source family evaluation(s)."
    )

    if failures:
        print("\nOpen audio source survey check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Open audio source survey check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
