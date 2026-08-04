# 實器錄音專業審聽規則

日期：2026-06-15

## 目的

國樂專業者會立刻聽出假的胡琴、吹管、彈撥與打擊音色。這份規則用來確保實器錄音在匯入 App 前，已經由熟悉國樂音色的人審聽，而不是只靠檔案格式或授權文字通過。

## 審聽資料

- 完整錄音交付包：`Design/Source/VerifiedAudio/procurement/full_open_recording_delivery_pack.json`
- 第一批錄音交付包：`Design/Source/VerifiedAudio/procurement/priority1_recording_delivery_pack.json`
- 收件資料夾：`Design/Source/VerifiedAudio/inbox/full/<instrument_id>/`
- 笙複核資料夾：`Design/Source/VerifiedAudio/inbox/reverify/sheng/`
- 授權檔：`Design/Source/VerifiedAudio/inbox/full/<instrument_id>/<instrument_id>.release.json`
- 專業審聽表：`Design/Source/VerifiedAudio/procurement/professional_listening_review_scorecard.json`

## 評分規則

每件樂器至少需要 1 位國樂專業者審聽，建議 2 位。演奏者可以補充說明，但不能成為自己錄音的唯一最終審核者。

每項 1 到 5 分，單項不得低於 4 分，平均不得低於 4.25 分：

- 樂器辨識正確。
- 專業音色可信。
- 技法代表性。
- 錄音乾淨度。
- 適合練習室訓練。

審聽通過的 `review_records` 必須有 `decision: "approved_for_import"`。未通過者不得執行 `import_verified_audio.py --approve`。

`applies_to_open_instrument_ids` 追蹤 21 件缺正式音檔的 open 樂器；`applies_to_reverify_instrument_ids` 追蹤第一批複核的笙 `sheng`。嚴格送審 gate 會把 open 與 reverify 一起看，所以笙不能因為已有舊 approved 來源就跳過專業聽感複核。

## 禁止來源

核心音色不得使用 Suno、VST、sample library、MIDI 音源、YouTube/CD/串流擷取，或任何無法證明可商用的來源。Suno 只能作為非核心伴奏或氛圍素材候選，不能替代二胡、高胡、中胡、革胡、笙、嗩吶等實器音色。

## 批次匯入

收到完整資料夾後，先跑：

```bash
python3 fastlane/scripts/check_recording_inbox.py --strict
python3 fastlane/scripts/check_phase1_recording_inbox.py --strict
python3 fastlane/scripts/check_professional_listening_scorecard.py --strict
```

如果只想確認目前哪些檔案能匯入：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py
```

若要對完整且審聽通過的資料夾做 dry-run：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py --instrument-id erhu
```

若是第一批 7 件，尤其包含 `sheng` 複核資料夾，請指定 priority1 pack：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1 --instrument-id sheng
```

人工確認 dry-run 輸出、授權、審聽紀錄都正確後，才能正式匯入：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py --instrument-id erhu --approve
```

批次匯入器會呼叫 `import_verified_audio.py --approve`，更新 verified audio manifest 與 App bundle WAV。匯入後仍需重跑嚴格 readiness、重截 iPhone 6.9 / iPad 13 截圖，並完成 StoreKit 與 App Store Connect 檢查。
