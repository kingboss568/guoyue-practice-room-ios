# Verified Recording Inbox

Place performer deliveries under one folder per instrument:

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

Each instrument folder must contain the exact take filenames from
`Design/Source/VerifiedAudio/procurement/full_open_recording_delivery_pack.json`
plus `<instrument_id>.release.json`.

Before import, run:

```bash
python3 fastlane/scripts/check_recording_inbox.py
```

Do not copy inbox audio into the app bundle by hand. Use
`fastlane/scripts/import_verified_audio.py` after license, technical, and
professional listening review are complete.
