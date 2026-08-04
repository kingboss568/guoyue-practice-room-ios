# 第一批高風險實器錄音交付包

日期：2026-06-15

## 目的

第一批只處理專業演奏者最容易聽出假的 7 件：二胡、高胡、中胡、革胡、笙、嗩吶、板胡。這批音檔必須優先委託真人演奏者錄製，不接受 Suno、AI、VST、sample library、YouTube/CD/串流擷取。

機器可檢查規格在：

- `Design/Source/VerifiedAudio/procurement/priority1_recording_delivery_pack.json`
- `Design/Source/VerifiedAudio/procurement/priority1_release_templates/*.release.template.json`
- `fastlane/scripts/check_phase1_recording_inbox.py`

## 交付資料夾

演奏者或樂團回傳後，6 件仍缺 approved 音檔的高風險樂器放入正式收件路徑：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

例如：

```text
Design/Source/VerifiedAudio/inbox/full/erhu/
├── erhu_take1_open_string_or_sustained_tone.wav
├── erhu_take2_expressive_slide.wav
├── erhu_take3_original_short_phrase.wav
└── erhu.release.json
```

笙已有 approved 來源，但本批仍要做專業 reverify；若收到笙的新錄音或複審資料，放入：

```text
Design/Source/VerifiedAudio/inbox/reverify/sheng/
```

## 檔名與 take

每件樂器至少 3 個 take，每個 take 至少 6 秒乾淨聲音，建議 10 秒。詳細檔名與內容在 `priority1_recording_delivery_pack.json`。

高風險拒收條件：

- 聽起來像 AI、VST、取樣器或 pitch-shift。
- 有伴奏、節拍器、背景音樂或環境噪音壓過主樂器。
- 使用仍受著作權保護的旋律，且沒有另附作曲授權。
- 沒有簽署可商用 App 內散布、剪輯、轉檔、全球永久使用的授權。

## Release JSON

每件樂器已有範本：

```text
Design/Source/VerifiedAudio/procurement/priority1_release_templates/<instrument_id>.release.template.json
```

使用時請複製到 inbox 並改名為：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/<instrument_id>.release.json
```

笙複審則使用：

```text
Design/Source/VerifiedAudio/inbox/reverify/sheng/sheng.release.json
```

必須替換所有 `TO_BE_FILLED` 值，並移除 `template_only` 或改為 `false`。`import_verified_audio.py` 會拒絕範本或仍含 placeholder 的 release JSON。

## 匯入

收到音檔與授權後先 dry-run：

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take1_open_string_or_sustained_tone.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take2_expressive_slide.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take3_original_short_phrase.wav \
  --release Design/Source/VerifiedAudio/inbox/full/erhu/erhu.release.json
```

`--source` 可重複多次；匯入器會把每個 take 轉成審查格式，並串接為單一 App master。試聽、授權確認與專業聽辨通過後才加 `--approve`，approve 後 manifest 會保留每個原始 take 的路徑與 SHA-256。

批次 dry-run 第一批資料夾時，使用：

```bash
python3 fastlane/scripts/check_phase1_recording_inbox.py
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1
```

笙複核資料也在這個 priority1 pack 內，不在完整 21 件 open-instrument pack 內。
