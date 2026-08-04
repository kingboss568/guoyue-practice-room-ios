# 上架自我檢核

## 已完成

- iPhone / iPad Universal target
- SwiftUI app 可在 iOS Simulator build and run
- App Icon 已生成並接入 AppIcon asset catalog
- 22 張具來源與商用授權的真實樂器照片已加入 Assets.xcassets；排鼓維持中性待補卡
- 16 段具來源與商用授權的實器 WAV 已加入 bundle；其餘 7 種只開啟可追溯的原站真人示範，不複製影音、不以合成或相近樂器替代
- 23 種樂器各 50 題（共 1150 題）、230 題基礎知識、48 題核准音源聽辨題已加入
- 樂庫已支援樂器／作曲家／年代搜尋篩選，並加入 27 個國樂相關連結
- StoreKit 2 Pro 解鎖入口已加入
- 本機學習進度、收藏、測驗紀錄已加入
- Privacy Manifest 已加入 `PrivacyInfo.xcprivacy`
- Support page 已加入 repo
- Privacy Policy 已加入 repo
- App Store listing copy 已加入 repo
- Review notes 已加入 repo
- Fastlane metadata、screenshots 目錄、既有 Cloud build 選取與 submit gate 已加入；沒有本機 binary lane
- IAP manifest 已加入 `fastlane/iap/products.json`
- `Info.plist` 空白 scene manifest 風險已修正，避免啟動後無 scene 白畫面
- iPhone 6.9 吋與 iPad 13 吋已完成新版功能與版面 QA；這是開發驗證，不等同最終 App Store 截圖
- Xcode 27 beta 已完成無簽章 Simulator Debug build；沒有建立本機 archive 或 IPA

## 送審前仍需在 App Store Connect 完成

- 建立 Non-Consumable IAP：`com.yuhsiangjiang.GuoYueZhiPu.pro`
- 將 IAP 狀態設為可提交審查
- 將 IAP 加入目前 App version 的審查項目
- 將 Support URL 指到 Git repo 中的 `Docs/Support.md`
- 將 Privacy Policy URL 指到 Git repo 中的 `Docs/PrivacyPolicy.md`
- 補齊並上傳 iPhone 6.9 吋與 iPad 13 吋截圖：每種裝置至少 6 張、不重複、不空白，且包含 Pro 付款頁面
- 音檔與樂器圖嚴格 gate 通過後，依 `Docs/ScreenshotRecapturePlan.zh-Hant.md` 重截截圖，並將 `fastlane/screenshots/zh-Hant/screenshot_manifest.json` 標記為 `current_after_redesign`
- 確認 16 種內建實器音源與 7 個原站真人示範連結均可用；排鼓在取得可商用完整實拍前維持清楚的待補卡與官方來源連結
- 選擇正確 Team：Yu Shiung Jiang
- 確認 App Privacy：不收集資料、無追蹤
- 確認 repo 已 push，Support / Privacy Policy 可由 App Store Connect URL 公開讀取

## 風險檢查

- App 不宣稱替代正式音樂考級或專業師資。
- 內容定位為教育與導聆，不提供醫療、金融、法律等高風險建議。
- 不得把舊版生成音色視為專業音源；音檔與圖片需保留來源、授權與校對紀錄。
- 不可用 `deliver` 成功代表 IAP 已建立；IAP 需另行於 App Store Connect 建立與附加。
- 不可用 metadata lane 成功代表 binary 已上傳；正式 binary 只能由 Xcode Cloud `Archive → App Store Connect` 產生並確認為精確的 `VALID` build。
