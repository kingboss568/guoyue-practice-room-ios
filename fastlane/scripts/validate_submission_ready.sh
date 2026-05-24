#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STRICT_READY="${STRICT_READY:-1}"

cd "$ROOT"

failures=()

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
  printf '\nSubmission readiness check failed:\n'
  for failure in "${failures[@]}"; do
    printf -- '- %s\n' "$failure"
  done
  exit 1
fi

echo "Submission readiness checks passed."
