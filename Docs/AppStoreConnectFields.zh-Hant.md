# App Store Connect 填寫資料

## App Information

- Name: 國樂團練習室
- Subtitle: 樂器圖鑑、名曲導聆與聽辨練習
- Bundle ID: com.yuhsiangjiang.GuoYueZhiPu
- Version: 1.1（現行商店版 1.0 為 READY_FOR_SALE）
- SKU: GUOYUE-PRACTICE-ROOM-2026
- Primary Language: 繁體中文
- Category: Education
- Secondary Category: Music
- Age Rating: 4+
- Price: Free

## URLs

- Support URL: https://github.com/kingboss568/guoyue-practice-room-ios/blob/main/Docs/Support.md
- Privacy Policy URL: https://github.com/kingboss568/guoyue-practice-room-ios/blob/main/Docs/PrivacyPolicy.md
- Marketing URL: 留空

## Promotional Text

為國樂演奏者與教師整理 23 件樂器、四大聲部、名曲名家、聽辨提示與練團前複習路線。

## Description

國樂團練習室是一款為國樂初學者、音樂教師、導聆講師與國樂愛好者設計的離線學習 App。

你可以用圖鑑快速認識吹管、彈撥、拉弦、打擊四大聲部，查看每件樂器的音域、技法、定弦、代表曲目與完整介紹；已核准的實器音源會提供試聽與聆聽提示，尚未核准的樂器則清楚標示來源狀態。

App 內建名曲名家導聆、短課程、測驗與學習進度紀錄。免費版在每種樂器、基礎知識與實器聽辨皆可實際試做；Pro 版解鎖 23 種樂器各 50 題、230 題基礎知識與目前全部已核准實器聽辨題。

主要功能：

- 23 件國樂器圖鑑；22 件已有真實授權照片，排鼓在合格實拍補齊前顯示待補卡
- 吹管、彈撥、拉弦、打擊四大聲部導覽
- 音源來源狀態標示與已核准樣本試聽
- 名曲與名家導聆
- 入門課程、測驗與本機學習進度
- 收藏樂器與今日練習路線
- Pro 完整樂器、基礎知識與已核准實器聽辨題庫

隱私設計：

- 不需登入
- 無廣告
- 無第三方追蹤
- 學習紀錄只儲存在裝置本機

## Keywords

國樂,國樂團,中國樂器,二胡,琵琶,古箏,笛子,嗩吶,音樂教育,聽辨

## Copyright

Copyright © 2026 Yu Shiung Jiang

## In-App Purchase

- Type: Non-Consumable
- Reference Name: 國樂團練習室 Pro
- Product ID: com.yuhsiangjiang.GuoYueZhiPu.pro
- Display Name zh-Hant: 國樂團練習室 Pro
- Description zh-Hant: 解鎖23種樂器各50題、230題基礎知識與已授權實器聽辨；一次購買並支援恢復。
- Suggested Price: NT$190
- Must be attached to this App Store version before final review submission.
- Review screenshot must show the Pro purchase page with the unlock and restore purchase controls.

## App Privacy

- Data Collection: No data collected
- Tracking: No
- Third-Party Advertising: No
- Third-Party Analytics: No
- Account Creation: No
- User Login: No
- IDFA: Not used

## Review Information

- Sign-in required: No
- Demo account: Not needed
- Contact First Name: Yu Shiung
- Contact Last Name: Jiang
- Phone: +886952413678
- Email: jushiung@gmail.com

## Review Notes

國樂團練習室是一款離線國樂教育 App。新版只顯示具可稽核來源與商用授權的真實樂器照片及實器錄音；未完成的項目會明確停用，不以 AI、合成音或相近樂器替代。

App 不需要登入，不收集個人資料，不使用廣告 SDK，不使用第三方分析 SDK。學習進度、收藏與測驗紀錄僅透過 UserDefaults 儲存在使用者裝置本機。

Pro 付費功能使用 Apple StoreKit：

- Product ID: com.yuhsiangjiang.GuoYueZhiPu.pro
- Type: Non-Consumable
- Unlock name: 國樂團練習室 Pro

若審查環境尚未載入商品，App 會顯示「尚未連到 App Store Connect 商品」並保留恢復購買入口，不會閃退或阻擋免費內容。

## Demo Flow

1. 開啟 App 後進入「總覽」。
2. 點選「樂器」查看 23 件樂器；21 件顯示可追溯授權的真實實拍，革胡與排鼓在授權取得前顯示待補狀態。
3. 任選已取得授權實器音源的樂器，點選「試聽已授權實器片段」；缺件樂器會停用播放。
4. 回到「練功」，實際完成樂器、基礎與實器聽辨免費試用，並檢查 Pro 完整題庫說明。
5. 前往「Pro」頁查看 StoreKit 解鎖入口與恢復購買。

## Export Compliance

- Uses encryption: No custom encryption.
- Uses HTTPS / StoreKit only through Apple system frameworks.

## Content Rights

- App content: Original local educational dataset.
- Instrument artwork: bundled only after source/reference audit and professional morphology review.
- Audio: bundled only after verified real-instrument source or explicit commercial-use release is recorded in the manifest.
- Third-party media: no unlicensed third-party media; any approved CC/direct-license asset must be listed in `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json` or the artwork audit files.

## fastlane Lanes

- `fastlane ios validate_local`
- `fastlane ios upload_metadata`
- `fastlane ios prepare_cloud_submission`
- 由 Xcode Cloud `Archive - iOS` 產生並上傳 binary，並在 App Store Connect 確認狀態為 `VALID`
- `ASC_BUILD_NUMBER=<Cloud build> CONFIRM_SUBMIT_FOR_REVIEW=yes fastlane ios submit_review`
