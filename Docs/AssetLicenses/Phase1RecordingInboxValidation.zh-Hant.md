# 第一批實器錄音 Inbox 驗收規則

日期：2026-06-15

本規則專門對應 `priority1_recording_delivery_pack.json`，用來驗收二胡、高胡、中胡、革胡、笙、嗩吶、板胡這 7 件第一批高風險樂器。它不是匯入指令，也不是通過證明；它只負責在外部錄音送進 App 前，先抓出缺檔、錯路徑、錯授權、時長不足或漏掉專業審聽的問題。

## 收件位置

二胡、高胡、中胡、革胡、嗩吶、板胡的新錄音放到：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

笙的複核資料或新錄音放到：

```text
Design/Source/VerifiedAudio/inbox/reverify/sheng/
```

每個資料夾內要有 3 個 manifest 指定 take，以及一份 `<instrument_id>.release.json`。

## 禁止來源

第一批樂器最容易被專業演奏者聽出真假，所以禁用來源比一般素材更嚴格：

- Suno、Udio、MusicGen、Stable Audio。
- AI-generated instrument tone。
- VST、sample library、MIDI、synthesizer、GarageBand 音色。
- YouTube、Spotify、Apple Music、CD rip 或 streaming extraction。
- 相鄰樂器 pitch-shift / time-stretch。
- 未確認作曲權的受保護旋律。

即使平台授權標示可商用，也不能把生成音樂或音色庫當作核心國樂實器音檔。

## 驗收指令

一般收件檢查：

```bash
python3 fastlane/scripts/check_phase1_recording_inbox.py
```

嚴格模式會要求完整資料夾必須已有 `approved_for_import` 專業審聽紀錄：

```bash
python3 fastlane/scripts/check_phase1_recording_inbox.py --strict
```

第一批批次 dry-run 匯入使用 priority1 pack：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1 --instrument-id sheng
```

正式匯入前仍需人工確認 release、原始音檔、專業審聽紀錄與 dry-run 輸出。只有確認後才能加：

```bash
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1 --instrument-id erhu --approve
```

## 送審前狀態

第一批 7 件全部通過，不代表完整 22 件目標完成。重新送審前仍要完成：

- 剩餘 21 件 open 樂器都取得 approved 實器音檔。
- 笙 reverify 通過專業審聽或以新錄音取代。
- 來源 release、hash、verified manifest、App bundle WAV 對得上。
- 圖片專業審核、StoreKit paywall、iPhone 6.9 / iPad 13 截圖與 ASC IAP 附加都完成。
