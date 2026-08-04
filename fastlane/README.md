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

Local preflight: plist, JSON, IAP, asset, and screenshot manifest checks. Allows in-progress warnings.

### ios validate_submission

```sh
[bundle exec] fastlane ios validate_submission
```

Strict pre-submit gate. Fails if assets, screenshots, git push, or required files are incomplete.

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Strict-gated upload of App Store metadata and screenshots only. Does not upload a binary or submit review.

### ios prepare_cloud_submission

```sh
[bundle exec] fastlane ios prepare_cloud_submission
```

Strict-gated App Store listing preparation for Xcode Cloud. Never creates or uploads a local binary.

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Select an existing VALID Xcode Cloud build and submit. Requires ASC_BUILD_NUMBER and explicit confirmation.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
