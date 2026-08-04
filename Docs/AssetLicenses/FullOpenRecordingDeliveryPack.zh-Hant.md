# 國樂團練習室剩餘 21 件實器錄音完整交付包

日期：2026-06-15

## 目的

本文件對應 `Design/Source/VerifiedAudio/procurement/full_open_recording_delivery_pack.json`，列管所有目前尚未有正式核准音檔的國樂樂器。這個交付包不是音檔本身，而是錄音、授權、收件與審查的規格鎖。

核心規則：

- 只能使用真實樂器錄音。
- 不接受 Suno、Udio、其他生成式音樂輸出。
- 不接受 VST、sample library、合成器或鍵盤音色。
- 不接受 YouTube、CD、串流、社群影片或未授權網路音檔擷取。
- 曲目內容以單音、音階、代表性技法、打擊單擊、短即興句為主。
- 若包含仍受著作權保護的旋律，必須另附曲目授權，未確認前不得匯入 App。
- 每件樂器匯入前都要通過來源/授權檢查、技術音質檢查、國樂專業審聽。

## 目前 open 樂器

`verified_audio_sources.json` 目前已核准笛與笙；剩餘 21 件需要補齊：

| 優先 | 樂器 |
| --- | --- |
| 1 | 二胡、高胡、中胡、革胡、嗩吶、板胡 |
| 2 | 簫、管子、琵琶、古箏、揚琴、柳琴、中阮、三弦、箜篌 |
| 3 | 編鐘、堂鼓、鑼、鈸、木魚、排鼓 |

完整的逐件 take 規格、檔名、收件資料夾與拒收條件以 JSON 為準：

```bash
python3 fastlane/scripts/check_full_open_recording_pack.py
```

## 交付位置

每件樂器請放到：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

例：

```text
Design/Source/VerifiedAudio/inbox/full/erhu/
Design/Source/VerifiedAudio/inbox/full/suona/
Design/Source/VerifiedAudio/inbox/full/paigu/
```

## 授權模板

每件樂器都有一份 release template：

```text
Design/Source/VerifiedAudio/procurement/full_release_templates/<instrument_id>.release.template.json
```

收件時複製到對應 inbox，改名為：

```text
<instrument_id>.release.json
```

並替換所有 `TO_BE_FILLED` 欄位。release 必須確認：

- `real_instrument_recording`
- `commercial_app_distribution`
- `derivative_processing_allowed`
- `global_perpetual_use`
- `not_ai_generated`
- `not_vst_or_sample_library`
- `not_ripped_from_streaming_or_video`

## 匯入流程

收到音檔後先 dry-run：

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take1_open_string_or_sustained_tone.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take2_expressive_slide.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take3_original_short_phrase.wav \
  --release Design/Source/VerifiedAudio/inbox/full/erhu/erhu.release.json
```

確認音色、授權與專業審聽後才可加入 `--approve` 匯入正式 App bundle。

## 上架 gate

總檢查會跑：

```bash
STRICT_READY=1 bash fastlane/scripts/validate_submission_ready.sh
```

正式送審前，這個 gate 必須證明：

- 21 件 open 音檔都已取得可商用、可稽核的實器來源。
- App bundle 只包含已核准音檔。
- 來源 manifest、原始檔 hash、轉檔後 WAV、授權文件互相對得上。
- 專業審聽後沒有 AI/VST/錯樂器音色混入。
