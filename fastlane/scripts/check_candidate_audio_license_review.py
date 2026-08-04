#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AUDITIONS = ROOT / "Design" / "Source" / "VerifiedAudio" / "candidates" / "candidate_auditions.json"
LICENSE_PACK = (
    ROOT
    / "Design"
    / "Source"
    / "VerifiedAudio"
    / "procurement"
    / "candidate_license_review_pack.json"
)
DOC = ROOT / "Docs" / "AssetLicenses" / "CandidateAudioLicenseReview.zh-Hant.md"
APP_AUDIO = ROOT / "GuoYueZhiPu" / "Resources" / "Audio" / "Instruments"

REQUIRED_GLOBAL_TOKENS = {
    "attribution",
    "ShareAlike",
    "professional",
    "import_verified_audio.py",
}

REQUIRED_DOC_TOKENS = [
    "blocked_pending_license_and_professional_review",
    "不得複製到",
    "CC BY-SA 4.0",
    "Attribution",
    "ShareAlike",
    "Professional listening",
    "import_verified_audio.py --approve",
]


def load_json(path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    failures = []

    auditions = load_json(AUDITIONS)
    pack = load_json(LICENSE_PACK)
    doc_text = DOC.read_text(encoding="utf-8") if DOC.exists() else ""

    if pack.get("status") != "review_pack_current":
        failures.append("candidate license review pack status must be review_pack_current")

    policy_summary = str(pack.get("policy_summary", ""))
    for token in ["CC BY-SA", "commercial", "professional listening", "Candidate files must remain outside"]:
        if token not in policy_summary:
            failures.append(f"policy_summary missing token: {token}")

    global_requirements = "\n".join(pack.get("global_requirements_before_bundle", []))
    for token in REQUIRED_GLOBAL_TOKENS:
        if token not in global_requirements:
            failures.append(f"global requirements missing token: {token}")

    audition_by_id = {
        item.get("instrument_id"): item
        for item in auditions.get("items", [])
        if item.get("license") == "CC BY-SA 4.0"
    }
    pack_by_id = {item.get("instrument_id"): item for item in pack.get("items", [])}

    missing = sorted(set(audition_by_id) - set(pack_by_id))
    extra = sorted(set(pack_by_id) - set(audition_by_id))
    if missing:
        failures.append("license review pack missing audition candidates: " + ", ".join(missing))
    if extra:
        failures.append("license review pack has non-audition candidates: " + ", ".join(extra))

    for instrument_id, audition in sorted(audition_by_id.items()):
        item = pack_by_id.get(instrument_id)
        if not item:
            continue

        for field in [
            "source_title",
            "source_url",
            "author",
            "license",
            "license_url",
            "local_original_path",
            "local_audition_wav_path",
        ]:
            if item.get(field) != audition.get(field):
                failures.append(f"{instrument_id}: {field} must match candidate_auditions.json")

        if item.get("app_bundling_status") != "blocked_pending_license_and_professional_review":
            failures.append(f"{instrument_id}: app_bundling_status must remain blocked")
        if item.get("commercial_use_in_principle") is not True:
            failures.append(f"{instrument_id}: commercial_use_in_principle must be true for CC BY-SA review")
        for field in [
            "attribution_required",
            "share_alike_review_required",
            "change_notice_required",
            "professional_listening_required",
        ]:
            if item.get(field) is not True:
                failures.append(f"{instrument_id}: {field} must be true")
        if not str(item.get("review_notes", "")).strip():
            failures.append(f"{instrument_id}: review_notes is required")

        audition_path = ROOT / item.get("local_audition_wav_path", "")
        app_path = APP_AUDIO / f"{instrument_id}.wav"
        if app_path.exists() and audition_path.exists() and sha256(app_path) == sha256(audition_path):
            failures.append(f"{instrument_id}: candidate audition WAV has been copied into app bundle before approval")

    if not DOC.exists():
        failures.append("Missing CandidateAudioLicenseReview.zh-Hant.md")
    else:
        for token in REQUIRED_DOC_TOKENS:
            if token not in doc_text:
                failures.append(f"CandidateAudioLicenseReview.zh-Hant.md missing token: {token}")

    print(f"Candidate audio license review: {len(pack.get('items', []))} candidate(s)")

    if failures:
        print("\nCandidate audio license review check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Candidate audio license review check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
