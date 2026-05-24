fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios validate_local

```sh
[bundle exec] fastlane ios validate_local
```

Local preflight: plist, JSON, IAP manifest, and screenshot dimensions. Allows known missing sixth screenshots.

### ios validate_submission

```sh
[bundle exec] fastlane ios validate_submission
```

Strict pre-submit gate. Fails if screenshots, git push, or required files are incomplete.

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload App Store metadata and screenshots only. Does not upload a binary or submit review.

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build an App Store IPA using Xcode automatic signing.

### ios upload_ipa

```sh
[bundle exec] fastlane ios upload_ipa
```

Upload the IPA only. Requires a built IPA at Build/AppStore/GuoYueZhiPu.ipa unless IPA_PATH is set.

### ios release_candidate

```sh
[bundle exec] fastlane ios release_candidate
```

Build and upload metadata, screenshots, and IPA, but stop before final App Review submission.

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Final strict submit for review. Requires CONFIRM_SUBMIT_FOR_REVIEW=yes and strict readiness.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
