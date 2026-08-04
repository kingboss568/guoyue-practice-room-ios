#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_IDS = {"gehu", "suona", "sheng", "banhu", "erhu", "gaohu", "zhonghu"}
REFERENCE_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "artwork_reference_sources.json"
)
PROMPT_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "artwork_regeneration_prompts.json"
)
MORPHOLOGY_PATH = (
    ROOT
    / "Design"
    / "Source"
    / "InstrumentReferenceAudit"
    / "high_risk_artwork_morphology_specs.json"
)


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def nonempty_list(value, minimum=1):
    return isinstance(value, list) and len([item for item in value if str(item).strip()]) >= minimum


def main() -> int:
    failures = []

    references = load_json(REFERENCE_PATH)
    prompts = load_json(PROMPT_PATH)
    morphology = load_json(MORPHOLOGY_PATH)

    if references.get("minimum_reference_urls_per_instrument") != 2:
        failures.append("artwork_reference_sources minimum_reference_urls_per_instrument must be 2")

    generation_policy = references.get("image_generation_policy", {})
    for key in ["use_references_for", "do_not_copy", "professional_gate"]:
        if not str(generation_policy.get(key, "")).strip():
            failures.append(f"artwork_reference_sources.image_generation_policy.{key} is required")

    reference_by_id = {item.get("instrument_id"): item for item in references.get("sources", [])}
    prompt_by_id = {item.get("instrument_id"): item for item in prompts.get("prompts", [])}
    spec_by_id = {item.get("instrument_id"): item for item in morphology.get("specs", [])}

    for label, lookup in [
        ("artwork reference source", reference_by_id),
        ("artwork regeneration prompt", prompt_by_id),
        ("morphology spec", spec_by_id),
    ]:
        missing = sorted(REQUIRED_IDS - set(lookup))
        unknown = sorted(set(lookup) - REQUIRED_IDS)
        if missing:
            failures.append(f"{label} missing high-risk instruments: " + ", ".join(missing))
        if unknown:
            failures.append(f"{label} has unknown high-risk instruments: " + ", ".join(unknown))

    if prompts.get("reference_manifest") != "Design/Source/InstrumentReferenceAudit/artwork_reference_sources.json":
        failures.append("artwork_regeneration_prompts reference_manifest must point to artwork_reference_sources.json")
    if "professional approval" not in str(prompts.get("approval_gate", "")).lower():
        failures.append("artwork_regeneration_prompts approval_gate must require professional approval")

    for instrument_id in sorted(REQUIRED_IDS):
        reference = reference_by_id.get(instrument_id)
        prompt = prompt_by_id.get(instrument_id)
        spec = spec_by_id.get(instrument_id)
        if not reference or not prompt or not spec:
            continue

        urls = reference.get("reference_urls", [])
        if not nonempty_list(urls, 2):
            failures.append(f"{instrument_id}: at least two reference_urls are required")
        if len(set(urls)) != len(urls):
            failures.append(f"{instrument_id}: duplicate reference_urls are not allowed")

        if not nonempty_list(reference.get("morphology_constraints"), 5):
            failures.append(f"{instrument_id}: at least five morphology_constraints are required")
        if "copy" not in str(reference.get("copy_policy", "")).lower():
            failures.append(f"{instrument_id}: copy_policy must explicitly forbid copying references")

        source_notes = reference.get("source_notes", [])
        if not isinstance(source_notes, list) or len(source_notes) < 2:
            failures.append(f"{instrument_id}: at least two source_notes are required")
        else:
            for note in source_notes:
                if note.get("url") not in urls:
                    failures.append(f"{instrument_id}: source_note url must appear in reference_urls")
                if not str(note.get("source_type", "")).strip():
                    failures.append(f"{instrument_id}: source_note source_type is required")
                if not nonempty_list(note.get("substantiated_features"), 2):
                    failures.append(f"{instrument_id}: source_note substantiated_features must include at least two entries")

        constraints = reference.get("image_generation_constraints", {})
        for key in ["required_positive_terms", "forbidden_confusions"]:
            if not nonempty_list(constraints.get(key), 4):
                failures.append(f"{instrument_id}: image_generation_constraints.{key} must include at least four entries")
        if constraints.get("review_against_spec") != f"high_risk_artwork_morphology_specs.json::{instrument_id}":
            failures.append(f"{instrument_id}: review_against_spec must reference the morphology spec")

        required_urls = prompt.get("reference_urls_required", [])
        if len(set(required_urls) & set(urls)) < 2:
            failures.append(f"{instrument_id}: prompt reference_urls_required must include at least two listed references")
        if prompt.get("approval_required_before_bundle") is not True:
            failures.append(f"{instrument_id}: prompt approval_required_before_bundle must be true")

        for key in ["required_positive_terms", "forbidden_confusions"]:
            prompt_values = set(prompt.get(key, []))
            constraint_values = set(constraints.get(key, []))
            missing_values = sorted(constraint_values - prompt_values)
            if missing_values:
                failures.append(f"{instrument_id}: prompt {key} missing reference constraints: " + ", ".join(missing_values))

        if set(prompt.get("must_show_checklist", [])) != set(spec.get("must_show", [])):
            failures.append(f"{instrument_id}: prompt must_show_checklist must match morphology spec")
        if set(prompt.get("must_not_show_checklist", [])) != set(spec.get("must_not_show", [])):
            failures.append(f"{instrument_id}: prompt must_not_show_checklist must match morphology spec")

    print(f"Artwork reference-backed prompts: {len(prompt_by_id)}/{len(REQUIRED_IDS)} high-risk instrument(s)")

    if failures:
        print("\nArtwork reference prompt check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Artwork reference prompt check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
