# 實器錄音 Inbox 驗收規則

日期：2026-06-15

本規則用來處理演奏者交來的真實錄音。它不會把任何音檔自動變成 approved；它只負責在 dry-run 或匯入前，先確認收件資料夾沒有缺檔、錯檔、缺授權或漏掉專業審聽。

## 收件位置

每件樂器交到：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

已 approved 但需要第一階段複審的笙，若有新錄音或補充審聽資料，交到：

```text
Design/Source/VerifiedAudio/inbox/reverify/sheng/
```

例如：

```text
Design/Source/VerifiedAudio/inbox/full/erhu/
Design/Source/VerifiedAudio/inbox/full/suona/
Design/Source/VerifiedAudio/inbox/full/banhu/
Design/Source/VerifiedAudio/inbox/reverify/sheng/
```

## 必備內容

每件樂器至少要有：

- `full_open_recording_delivery_pack.json` 指定的三個 take 檔名。
- `<instrument_id>.release.json`。
- WAV / AIFF / AIF 格式。
- 每個 take 至少 6 秒乾淨可用聲音。
- release 內確認：真實樂器錄音、可商用 App 散布、允許剪輯轉檔、全球永久使用、非 AI、非 VST/sample library、非 YouTube/CD/串流擷取。

## 禁用來源掃描

release 的 `source_title`、`source_type`、`performer_or_source`、`license_review`、`notes` 等文字也會被掃描；只要出現 Suno、Udio、MusicGen、Stable Audio、AI-generated、VST、sample library、MIDI、synthesizer、GarageBand、YouTube、Spotify、Apple Music、CD rip 或 streaming extraction，就不得匯入。

即使某個生成音樂服務標示可商用，仍不能當成國樂實器錄音。這個 App 的核心訓練素材要能被專業國樂演奏者聽辨與追溯，所以 Suno/AI 只能用於內部編曲草稿或非核心氛圍參考，不可放入付費聽辨、音色拆解或樂器示範。

## 嚴格模式

`STRICT_READY=1` 時，若 inbox 已收到完整檔案，還必須有 `professional_listening_review_scorecard.json` 裡對應的審聽紀錄，且 decision 為 `approved_for_import`。

通過 inbox 驗收仍不等於已匯入 App。正式匯入必須另外執行：

```bash
python3 fastlane/scripts/import_verified_audio.py --instrument-id <instrument_id> ... --approve
```

沒有 `--approve` 時只做 dry-run；有 `--approve` 才會更新 verified manifest 與 App bundle WAV。

若收到多件錄音，可以改用批次匯入器。它會先跑 inbox 與專業審聽 preflight，只匯入完整且 `approved_for_import` 的資料夾：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py
python3 fastlane/scripts/import_recording_inbox_batch.py --instrument-id erhu --approve
```

第一批 7 件高風險樂器要使用 priority1 收件規則，因為它包含 `Design/Source/VerifiedAudio/inbox/reverify/sheng/`：

```bash
python3 fastlane/scripts/check_phase1_recording_inbox.py --strict
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1
```

不可使用 `--allow-unreviewed` 做正式匯入；該參數只允許 dry-run 檢查未審聽資料夾。

## 驗證指令

```bash
python3 fastlane/scripts/check_recording_inbox.py
python3 fastlane/scripts/check_professional_listening_scorecard.py
STRICT_READY=0 bash fastlane/scripts/validate_submission_ready.sh
```

送審前：

```bash
STRICT_READY=1 bash fastlane/scripts/validate_submission_ready.sh
```

嚴格 gate 必須等音檔、授權、審聽、圖片、StoreKit、截圖都完成後才可通過。
