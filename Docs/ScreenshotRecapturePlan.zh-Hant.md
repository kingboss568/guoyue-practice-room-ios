# 國樂團練習室截圖重截計畫

日期：2026-06-15

## 目前狀態

`fastlane/screenshots/zh-Hant` 內已有 iPhone 6.9 與 iPad 13 各 6 張 PNG，尺寸檢查可以通過，但這批圖不是最終可送審素材。原因如下：

- 音檔目前只有 `dizi`、`sheng` 通過可商用、可稽核的實器錄音 gate。
- 樂器圖片仍有 `gehu`、`suona`、`sheng`、`banhu` 需要重做，`erhu` / `gaohu` / `zhonghu` 需要差異化校正。
- StoreKit paywall 已改版，現有截圖尚未證明包含新版付款、恢復購買與專業加值說明。

因此已新增 `fastlane/screenshots/zh-Hant/screenshot_manifest.json`，把目前 12 張圖標記為 `stale_pending_recapture`。`STRICT_READY=1` 會在 manifest 尚未標記為 `current_after_redesign` 前失敗，避免尺寸合格但內容過期的截圖被送審。

## 重截前門檻

重截前需先完成：

- `python3 fastlane/scripts/check_asset_authenticity.py --strict` 通過。
- `python3 fastlane/scripts/check_instrument_artwork_audit.py --strict` 通過。
- App 內 Pro paywall 已可載入 StoreKit 商品或在審查環境下有明確的載入/重試/恢復購買狀態。
- App Store metadata、review notes 與 paywall 不宣稱未完成的真實音色包。

## 必截畫面

每個裝置都要截 6 張，並維持同一組 screen role：

- `dashboard`：首頁/練習進度概覽。
- `instruments`：樂器列表，需顯示已校正後的樂器圖片。
- `library`：曲目或練習素材庫。
- `practice`：練習室播放/音色提示畫面。
- `pro`：Pro 加值說明頁，需反映專業演奏家價值。
- `payment`：StoreKit 購買/恢復購買流程或商品載入狀態，必須清楚可見。

## 重截後更新方式

1. 覆蓋或輸出新 PNG 到 `fastlane/screenshots/zh-Hant`。
2. 跑 `python3 fastlane/scripts/check_screenshots.py fastlane/screenshots/zh-Hant --min-per-device 6`。
3. 重新計算每張圖 SHA-256。
4. 更新 `screenshot_manifest.json`：
   - `status` 改為 `current_after_redesign`。
   - `generated_after_asset_gate` 改為 `true`。
   - `generated_after_paywall_redesign` 改為 `true`。
   - 每張截圖 `status` 改為 `current_after_redesign`。
   - 每張截圖 `sha256` 更新為新檔案雜湊。
5. 跑 `STRICT_READY=1 bash fastlane/scripts/validate_submission_ready.sh`，確認截圖、音檔、圖片、git push 與上架文件都通過後才可送審。
