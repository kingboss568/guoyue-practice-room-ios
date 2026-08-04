# 國樂團練習室 iOS

國樂團練習室是一款 SwiftUI 國樂教育與練習 App。它以樂器圖鑑、名曲導聆、分類搜尋、聽辨與知識練習、學習進度及 StoreKit Pro 解鎖為核心；新版已把未經核准的想像圖與合成音色移出可交付內容。

## 目前包含

- 23 件國樂器資料與四大聲部分類
- 22 張具逐檔來源與商用授權的真實樂器照片；排鼓在取得合格實拍前顯示中性待補卡
- 16 段具可稽核來源與商用授權的實器 WAV；其餘 7 種樂器只開啟原站真人示範，不複製影音、不提供假音檔或替代音色
- GPT Image 製作的 App Icon 與品牌主視覺
- SwiftUI 五頁籤：總覽、樂器、樂庫、練功、Pro
- 樂器／作曲家／年代分類搜尋、27 個國樂相關連結
- 23 種樂器各 50 題、230 題基礎知識、48 題以核准實器音檔建立的聽辨題
- 收藏樂器、完成課程、測驗最佳成績等本機學習進度
- StoreKit 2 Pro 解鎖入口
- Privacy Manifest
- App Store listing、Support、Privacy Policy、Review Notes

## Build

1. Open `GuoYueZhiPu.xcodeproj`.
2. Select scheme `GuoYueZhiPu`.
3. Use Team `Yu Shiung Jiang`.
4. 開發期間只以 iPhone 6.9 吋與 iPad 13 吋 Simulator 執行 Debug build 與版面檢查。

正式 binary 一律由 Xcode Cloud 的 `Archive → App Store Connect` workflow 產生。不得在本機產生 release archive 或 IPA；Fastlane 只處理 metadata、截圖、選取既有 `VALID` build 與送審。

CLI verification used during development:

```bash
xcodebuild -project GuoYueZhiPu.xcodeproj -scheme GuoYueZhiPu -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

## StoreKit Product

- Type: Non-Consumable
- Product ID: `com.yuhsiangjiang.GuoYueZhiPu.pro`
- Display Name: 國樂團練習室 Pro
- Suggested price: NT$190

Create the IAP in App Store Connect before final submission.

## Generated Media

Media assets are generated or copied by:

```bash
python3 Tools/generate_media_assets.py
```

This imports the approved GPT Image icon/banner masters, verified real-instrument photos, and approved real-instrument WAV masters. It never synthesizes missing audio or invents missing instrument photos; unavailable assets remain explicitly blocked in the App.

## Release Status

See `RELEASE_STATUS.md`. The redesign includes source-backed real media and explicit external-only references; App Store submission still requires current device QA, final screenshots, a clean pushed Git revision, an exact Xcode Cloud `VALID` build, and live App Store Connect proof.

## App Store Files

- `Docs/Support.md`
- `Docs/PrivacyPolicy.md`
- `Docs/AppStoreListing.zh-Hant.md`
- `Docs/ReviewNotes.zh-Hant.md`
- `Docs/ComplianceChecklist.zh-Hant.md`
- `Docs/IAP-Setup.md`
- `Docs/AssetAuthenticityAudit.zh-Hant.md`
- `Docs/CompetitiveResearchAndAssetPlan.zh-Hant.md`
