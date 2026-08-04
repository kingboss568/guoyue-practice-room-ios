# Verified Audio Inbox

Put newly received real-instrument recordings here before importing them into the app.

Required files for each instrument:

- Original audio, for example `erhu_take1.wav`
- Completed release metadata JSON, for example `erhu.release.json`

Dry-run validation:

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/erhu_take1.wav \
  --release Design/Source/VerifiedAudio/inbox/erhu.release.json
```

Approve and import:

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/erhu_take1.wav \
  --release Design/Source/VerifiedAudio/inbox/erhu.release.json \
  --approve
```

After importing, run:

```bash
python3 fastlane/scripts/check_asset_authenticity.py --strict
```

The importer rejects AI-generated, VST/sample-library, ripped, non-commercial, or unclear-license recordings.
