# 國樂團練習室 Release Status

更新日期：2026-08-04

狀態：`REDESIGN_AND_SCREENSHOTS_VERIFIED_CLOUD_PENDING`

## 身份與版本

- Apple 帳號：`jushiung@gmail.com`
- Team：Yu Shiung Jiang（`7H7ZUG2WX8`）
- Bundle ID：`com.yuhsiangjiang.GuoYueZhiPu`
- 商店現行版本：`1.0`（`READY_FOR_SALE`）
- 本次改版版本：`1.1`
- 本次改版 build：`202608040235`（只能由 Xcode Cloud 正式封存／上傳）
- IAP：`com.yuhsiangjiang.GuoYueZhiPu.pro`

## 已完成

- GPT Image App Icon、品牌 banner 與新版 SwiftUI 介面接入。
- 四大聲部與 23 種樂器皆可進入；樂器內容、樂庫分類搜尋、相關連結、練功及 Pro 試用流程已完成。
- 題庫：23 種樂器各 50 題，共 1150 題；基礎知識 230 題；16 組具授權實器音檔共 48 題聽辨。
- 真實樂器照片 22 / 23；排鼓保留明確無照片占位與官方實器參考，不放相近樂器替代圖。
- 具商用授權且實際內嵌的實器音檔 16 / 23；其餘 7 種只提供經稽核的外部原站實器示範，不複製、不熱連、不列入聽辨題。
- iPhone 6.9 吋與 iPad 13 吋完成開發版 UI／功能 QA，各 6 張新版商店截圖已重截並通過尺寸、內容與 checksum 驗證。
- 付款頁已由 Simulator 實際連上 App Store 商品，顯示正確商品 ID、購買／恢復控制與 `$5.99` 實際價格。
- Xcode 27 beta Simulator Debug build 成功；本輪未在本機建立 archive 或 IPA。`Build/AppStore/GuoYueZhiPu.ipa` 是 2026-05-28 留下且被 Git 忽略的舊版 1.0／build `202605282318`，本輪未修改、未選用、未上傳。
- `STRICT_READY=0` 完整驗證通過；Strict 素材與截圖閘門已就緒，尚待 ASC 1.1 附加 IAP 與 Git push 後跑最終 `STRICT_READY=1`。
- Support 與 Privacy Policy 已存在公開 repo；本輪 Support 精準化文字仍待與其餘改版一起安全 commit／push。
- ASC 純讀取已核對正確 Jiang App（App ID `6772708738`）、現行版 1.0／build `202605282318`、APPROVED 非消耗性 IAP（ASC ID `6773302182`）與價格排程。
- 已透過受控 ASC UI 建立不誇大的新繁中 IAP localization，API 驗證與 repo 文案完全一致；目前狀態為「準備提交」，尚未送審。

## 送審阻塞

1. App Store Connect 尚無 1.1 可編輯版本；需建立 1.1、附加已核准 IAP 與繁中 localization，並上傳新版 review screenshot。
2. 改版工作樹需完成範圍稽核、commit 與 push；Xcode Cloud 必須從已 push 的正確 commit 建立 Archive。
3. 尚未有本次 `202608040235` 的 Xcode Cloud Archive；必須等精確 build 在 App Store Connect 成為 `VALID` 才可選用。
4. 仍需以 Sandbox／審查帳號路徑驗證一次購買與恢復。Simulator 已證明商品可載入，但沒有虛構成功交易紀錄。

## 素材邊界

- 管子、箜篌、中胡、革胡、編鐘、堂鼓、排鼓目前是外部原站實器示範，不是 App 內試聽檔；高胡已新增具 CC BY-SA 4.0 授權的真實錄音。
- 排鼓目前沒有合規可再利用照片，因此 App 明確顯示無照片占位並連到官方實器資料；不以堂鼓或其他鼓組替代。
- 目前沒有填造具名專業審聽／形制審核紀錄；未來若取得新錄音或照片，仍須先完成真實專業審核才能匯入。

## 唯一允許的正式送件路徑

1. 先讓 `STRICT_READY=1 bash fastlane/scripts/validate_submission_ready.sh` 全部通過。
2. 由 Xcode Cloud 建立並執行 `Archive → App Store Connect` workflow。
3. 等待精確 build 在 App Store Connect 成為 `VALID`。
4. Fastlane 只上傳 metadata／截圖、以 `ASC_BUILD_NUMBER` 選取該既有 Cloud build，並在明確確認後送審。
5. 不在本機產生 release archive、IPA 或其他 binary。

## 稽核入口

- `Docs/AssetAuthenticityAudit.zh-Hant.md`
- `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json`
- `Design/Source/VerifiedPhotos/manifests/commons_photo_credits.json`
- `Design/Source/VerifiedAudio/procurement/performer_recording_work_order.json`
- `Design/Source/VerifiedAudio/procurement/professional_listening_review_scorecard.json`
- `fastlane/screenshots/zh-Hant/screenshot_manifest.json`
