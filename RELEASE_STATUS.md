# 國樂團練習室 Release Status

更新日期：2026-08-05

狀態：`SUBMITTED_WAITING_FOR_REVIEW`

## 身份與版本

- Apple 帳號：`jushiung@gmail.com`
- Team：Yu Shiung Jiang（`7H7ZUG2WX8`）
- App Store Connect App ID：`6772708738`
- Bundle ID：`com.yuhsiangjiang.GuoYueZhiPu`
- 商店現行版本：`1.0`（`READY_FOR_SALE`）
- 本次改版版本／建置：`1.1 (2)`
- ASC Build ID：`784659c7-e5fa-4def-adbc-b7187cbaa959`（`VALID`）
- Xcode Cloud Build：`82fa55a5-3979-435a-8f02-221e1ca44dfd`，workflow `Archive - iOS`
- IAP：`com.yuhsiangjiang.GuoYueZhiPu.pro`（ASC ID `6773302182`，Non-Consumable）
- Review submission：`e206011f-7c63-4729-9070-a112a91178f2`

## 已完成

- GPT Image App Icon、品牌 banner 與新版 SwiftUI 介面接入。
- 四大聲部與 23 種樂器皆可進入；樂器內容、樂庫分類搜尋、相關連結、練功及 Pro 試用流程已完成。
- 題庫：23 種樂器各 50 題，共 1150 題；基礎知識 230 題；16 組具授權實器音檔共 48 題聽辨。
- 真實樂器照片 22 / 23；排鼓保留明確無照片占位與官方實器參考，不放相近樂器替代圖。
- 具商用授權且實際內嵌的實器音檔 16 / 23；其餘 7 種只提供經稽核的外部原站實器示範，不複製、不熱連、不列入聽辨題。
- iPhone 6.9 吋與 iPad 13 吋完成開發版 UI／功能 QA，各 6 張新版商店截圖已重截並通過尺寸、內容與 checksum 驗證。
- 付款頁已由 Simulator 實際連上 App Store 商品，顯示正確商品 ID、購買／恢復控制與 `$5.99` 實際價格。
- Xcode 27 beta Simulator Debug build 成功；本輪未在本機建立 archive 或 IPA。`Build/AppStore/GuoYueZhiPu.ipa` 是 2026-05-28 留下且被 Git 忽略的舊版 1.0／build `202605282318`，本輪未修改、未選用、未上傳。
- `STRICT_READY=1` 完整驗證通過；題庫、真實素材、StoreKit、截圖、Git push 與上架資料閘門皆通過。
- Support 與 Privacy Policy 已存在公開 repo 並完成 push。
- Xcode Cloud `Archive - iOS` 成功產生 `1.1 (2)`；ASC API 驗證 build 為 `VALID`、`usesNonExemptEncryption=false`。
- Fastlane 僅上傳 metadata／12 張截圖、選取既有 Cloud build 與更新內容權利聲明；`skip_binary_upload=true`，未上傳本機 binary。
- Fastlane 延遲重試曾令前四張截圖各多一份；已依檔名、大小、MD5 與狀態精確刪除 8 筆重複紀錄，ASC 最終為 iPhone 6.9 與 iPad 13 各 6 張。
- App 審查資訊已補齊正確姓名、聯絡方式、StoreKit Product ID、免費試用與 Demo flow；內容權利聲明改為 `USES_THIRD_PARTY_CONTENT` 且保留完整授權揭露。
- 受控 App Store Connect 送審草稿同時包含 App `1.1 (2)` 與「國樂團練習室 Pro」IAP，兩項已於 submission `e206011f-7c63-4729-9070-a112a91178f2` 送出。

## App Store Connect 最終證據

- App version `1.1`：`WAITING_FOR_REVIEW`
- Review submission：`WAITING_FOR_REVIEW`
- Build `1.1 (2)`：`VALID`
- 提交項目：App 版本 1 項 + IAP 1 項，兩項均顯示「等待審查」
- 提交日期：2026-08-05 01:45（GMT+8）
- 發佈方式：核准後自動發佈
- 草稿剩餘項目：0

## 目前狀態

- 沒有尚待處理的本機上架阻塞；目前只等待 Apple 審查結果。
- `WAITING_FOR_REVIEW` 不代表已核准或已上架；若 Apple 提出問題，需以同一 App、build、submission 與 IAP 證據鏈處理。

## 素材邊界

- 管子、箜篌、中胡、革胡、編鐘、堂鼓、排鼓目前是外部原站實器示範，不是 App 內試聽檔；高胡已新增具 CC BY-SA 4.0 授權的真實錄音。
- 排鼓目前沒有合規可再利用照片，因此 App 明確顯示無照片占位並連到官方實器資料；不以堂鼓或其他鼓組替代。
- 目前沒有填造具名專業審聽／形制審核紀錄；未來若取得新錄音或照片，仍須先完成真實專業審核才能匯入。

## 本次採用的正式送件路徑

1. `STRICT_READY=1 bash fastlane/scripts/validate_submission_ready.sh` 全部通過。
2. Xcode Cloud 執行 `Archive - iOS → App Store Connect`，Build 2 成為 `VALID`。
3. Fastlane 上傳 metadata／截圖並以 `ASC_BUILD_NUMBER=2` 選取既有 Cloud build；沒有 binary upload。
4. 因既有 IAP 審查草稿不由 Fastlane 管理，最後以受控 App Store Connect 頁面把 App 與 IAP 合併為兩項 submission 並送出。
5. 全程未在本機產生或上傳 release archive、IPA 或其他 binary。

## 稽核入口

- `Docs/AssetAuthenticityAudit.zh-Hant.md`
- `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json`
- `Design/Source/VerifiedPhotos/manifests/commons_photo_credits.json`
- `Design/Source/VerifiedAudio/procurement/performer_recording_work_order.json`
- `Design/Source/VerifiedAudio/procurement/professional_listening_review_scorecard.json`
- `fastlane/screenshots/zh-Hant/screenshot_manifest.json`
- Xcode Cloud：`https://appstoreconnect.apple.com/teams/69a6de78-ba5a-47e3-e053-5b8c7c11a4d1/apps/6772708738/ci/builds/82fa55a5-3979-435a-8f02-221e1ca44dfd/summary`
- App Review：`https://appstoreconnect.apple.com/apps/6772708738/distribution/reviewsubmissions/details/e206011f-7c63-4729-9070-a112a91178f2`
