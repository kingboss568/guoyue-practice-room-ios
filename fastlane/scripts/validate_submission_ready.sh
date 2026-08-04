#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STRICT_READY="${STRICT_READY:-1}"

cd "$ROOT"

failures=()

clean_apple_double() {
  find . -name '._*' -print -delete 2>/dev/null || true
}

clean_apple_double

run_check() {
  local label="$1"
  shift
  local output

  if ! output="$("$@" 2>&1)"; then
    [[ -n "$output" ]] && printf '%s\n' "$output"
    failures+=("$label failed")
  elif [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
}

require_file() {
  local path="$1"
  if [[ ! -s "$path" ]]; then
    failures+=("Missing required file: $path")
  fi
}

require_file "Docs/PrivacyPolicy.md"
require_file "Docs/Support.md"
require_file "Docs/AppStoreConnectFields.zh-Hant.md"
require_file "Docs/AppStoreListing.zh-Hant.md"
require_file "Docs/ReviewNotes.zh-Hant.md"
require_file "Docs/IAP-Setup.md"
require_file "GuoYueZhiPu/Resources/PrivacyInfo.xcprivacy"
require_file "fastlane/iap/products.json"
require_file "fastlane/Fastfile"
require_file "fastlane/Deliverfile"

run_check "Privacy manifest lint" plutil -lint "GuoYueZhiPu/Resources/PrivacyInfo.xcprivacy"
run_check "Orchestra data JSON validation" jq empty "GuoYueZhiPu/Resources/chinese_orchestra_data_export.json"
run_check "IAP manifest JSON validation" jq empty "fastlane/iap/products.json"

run_check "IAP manifest validation" python3 "fastlane/scripts/check_iap_manifest.py"
run_check "Practice question bank validation" python3 "fastlane/scripts/check_practice_question_bank.py"
if [[ "$STRICT_READY" == "1" ]]; then
  run_check "StoreKit paywall validation" python3 "fastlane/scripts/check_storekit_paywall.py" --strict
else
  run_check "StoreKit paywall validation" python3 "fastlane/scripts/check_storekit_paywall.py"
fi
run_check "Audio procurement tracker validation" python3 "fastlane/scripts/check_audio_procurement_tracker.py"
run_check "Open audio source survey validation" python3 "fastlane/scripts/check_open_audio_source_survey.py"
run_check "Core audio source policy validation" python3 "fastlane/scripts/check_core_audio_source_policy.py"
run_check "Priority-1 recording delivery pack validation" python3 "fastlane/scripts/check_priority1_recording_pack.py"
run_check "Full open recording delivery pack validation" python3 "fastlane/scripts/check_full_open_recording_pack.py"
run_check "Recording work order validation" python3 "fastlane/scripts/check_recording_work_order.py"
run_check "Phase-1 professional handoff validation" python3 "fastlane/scripts/check_phase1_professional_handoff.py"
run_check "Phase-1 handoff export validation" python3 "fastlane/scripts/check_phase1_handoff_export.py"
# These files are future commissioned-recording intake gates. Without delivered
# performer files they must remain honest empty templates, not fabricated review
# records, and therefore are always checked in template/non-strict mode here.
run_check "Professional listening scorecard validation" python3 "fastlane/scripts/check_professional_listening_scorecard.py"
run_check "Recording inbox validation" python3 "fastlane/scripts/check_recording_inbox.py"
run_check "Phase-1 recording inbox validation" python3 "fastlane/scripts/check_phase1_recording_inbox.py"
run_check "Audio source disclosure validation" python3 "fastlane/scripts/check_audio_source_disclosure.py"
run_check "Candidate audio audition validation" python3 "fastlane/scripts/check_candidate_audio_auditions.py"
run_check "Candidate audio license review validation" python3 "fastlane/scripts/check_candidate_audio_license_review.py"
run_check "Artwork status disclosure validation" python3 "fastlane/scripts/check_artwork_status_disclosure.py"
run_check "Artwork reference prompt validation" python3 "fastlane/scripts/check_artwork_reference_prompts.py"
run_check "High-risk artwork visual review card validation" python3 "fastlane/scripts/check_artwork_visual_review_cards.py"
run_check "Artwork approval draft validation" python3 "fastlane/scripts/check_artwork_approval_drafts.py"
if [[ "$STRICT_READY" == "1" ]]; then
  run_check "Artwork candidate annotation validation" python3 "fastlane/scripts/check_artwork_candidate_annotations.py" --strict
else
  run_check "Artwork candidate annotation validation" python3 "fastlane/scripts/check_artwork_candidate_annotations.py"
fi
# Source-page identity, commercial license, image hash, and internal contact-sheet
# QC are the release evidence. The named-review scorecard remains an optional
# future professional review template and must never be filled with invented data.
run_check "High-risk artwork review scorecard validation" python3 "fastlane/scripts/check_artwork_review_scorecard.py"
if [[ "$STRICT_READY" == "1" ]]; then
  run_check "Professional asset authenticity" python3 "fastlane/scripts/check_asset_authenticity.py" --strict
  run_check "Instrument artwork audit" python3 "fastlane/scripts/check_instrument_artwork_audit.py" --strict
  run_check "High-risk artwork morphology specs" python3 "fastlane/scripts/check_artwork_morphology_specs.py" --strict
  run_check "Screenshot manifest recapture validation" python3 "fastlane/scripts/check_screenshot_manifest.py" --strict
else
  run_check "Professional asset authenticity" python3 "fastlane/scripts/check_asset_authenticity.py"
  run_check "Instrument artwork audit" python3 "fastlane/scripts/check_instrument_artwork_audit.py"
  run_check "High-risk artwork morphology specs" python3 "fastlane/scripts/check_artwork_morphology_specs.py"
  run_check "Screenshot manifest recapture validation" python3 "fastlane/scripts/check_screenshot_manifest.py"
fi
if [[ "$STRICT_READY" == "1" ]]; then
  run_check "Screenshot validation" python3 "fastlane/scripts/check_screenshots.py" "fastlane/screenshots/zh-Hant" --min-per-device 6
else
  run_check "Screenshot validation" python3 "fastlane/scripts/check_screenshots.py" "fastlane/screenshots/zh-Hant" --min-per-device 6 --allow-incomplete
fi

if ! git ls-files --error-unmatch Docs/PrivacyPolicy.md >/dev/null 2>&1; then
  failures+=("Docs/PrivacyPolicy.md is not tracked by git")
fi

if ! git ls-files --error-unmatch Docs/Support.md >/dev/null 2>&1; then
  failures+=("Docs/Support.md is not tracked by git")
fi

if [[ "$STRICT_READY" == "1" ]]; then
  clean_apple_double

  if [[ -n "$(git status --porcelain)" ]]; then
    failures+=("Working tree has uncommitted changes; commit and push before final submit")
  fi

  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    if ! git merge-base --is-ancestor HEAD '@{u}'; then
      failures+=("Current HEAD is not pushed to upstream")
    fi
  else
    failures+=("Current branch has no upstream; push branch before final submit")
  fi
fi

if (( ${#failures[@]} > 0 )); then
  clean_apple_double
  printf '\nSubmission readiness check failed:\n'
  for failure in "${failures[@]}"; do
    printf -- '- %s\n' "$failure"
  done
  exit 1
fi

clean_apple_double
echo "Submission readiness checks passed."
