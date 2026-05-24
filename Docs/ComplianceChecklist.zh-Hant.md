# 上架自我檢核

## 已完成

- iPhone / iPad Universal target
- SwiftUI app 可在 iOS Simulator build and run
- App Icon 已生成並接入 AppIcon asset catalog
- 23 張樂器原創插圖已加入 Assets.xcassets
- 23 段樂器離線聲音樣本已加入 bundle
- StoreKit 2 Pro 解鎖入口已加入
- 本機學習進度、收藏、測驗紀錄已加入
- Privacy Manifest 已加入 `PrivacyInfo.xcprivacy`
- Support page 已加入 repo
- Privacy Policy 已加入 repo
- App Store listing copy 已加入 repo
- Review notes 已加入 repo
- fastlane metadata、screenshots 目錄、IPA lane 與 submit gate 已加入
- IAP manifest 已加入 `fastlane/iap/products.json`
- `Info.plist` 空白 scene manifest 風險已修正，避免啟動後無 scene 白畫面

## 送審前仍需在 App Store Connect 完成

- 建立 Non-Consumable IAP：`com.yuhsiangjiang.GuoYueZhiPu.pro`
- 將 IAP 狀態設為可提交審查
- 將 IAP 加入目前 App version 的審查項目
- 將 Support URL 指到 Git repo 中的 `Docs/Support.md`
- 將 Privacy Policy URL 指到 Git repo 中的 `Docs/PrivacyPolicy.md`
- 補齊並上傳 iPhone 6.9 吋與 iPad 13 吋截圖：每種裝置至少 6 張、不重複、不空白，且包含 Pro 付款頁面
- 選擇正確 Team：Yu Shiung Jiang
- 確認 App Privacy：不收集資料、無追蹤
- 確認 repo 已 push，Support / Privacy Policy 可由 App Store Connect URL 公開讀取

## 風險檢查

- App 不宣稱替代正式音樂考級或專業師資。
- 內容定位為教育與導聆，不提供醫療、金融、法律等高風險建議。
- 所有媒體為本專案生成資產，避免第三方圖片或音訊授權風險。
- 不可用 `deliver` 成功代表 IAP 已建立；IAP 需另行於 App Store Connect 建立與附加。
- 不可用 `skip_binary_upload true` 的 metadata lane 代表 IPA 已上傳；IPA lane 必須明確 `skip_binary_upload: false`。
