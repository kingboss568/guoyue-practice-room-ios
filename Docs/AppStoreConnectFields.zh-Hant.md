# App Store Connect 填寫資料

## App Information

- Name: 國樂團練習室
- Subtitle: 樂器圖鑑、名曲導聆與聽辨練習
- Bundle ID: com.yuhsiangjiang.GuoYueZhiPu
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

從 23 件國樂器、四大聲部、名曲名家到離線聲音樣本，一次建立真正能聽懂國樂團的學習地圖。

## Description

國樂團練習室是一款為國樂初學者、音樂教師、導聆講師與華樂愛好者設計的離線學習 App。

你可以用圖鑑快速認識吹管、彈撥、拉弦、打擊四大聲部，查看每件樂器的音域、技法、定弦、代表曲目與完整介紹；也能透過原創生成的樂器插圖與本機聲音樣本，建立更具體的音色記憶。

App 內建名曲名家導聆、短課程、入門測驗與學習進度紀錄。免費版適合建立國樂團基礎地圖；Pro 版解鎖專家聽辨題庫、個人化練習路線、舞台編制分析與完整離線聲音包訓練提示，讓學習不只停留在瀏覽資料。

主要功能：

- 23 件國樂器圖鑑與原創插圖
- 吹管、彈撥、拉弦、打擊四大聲部導覽
- 每件樂器的離線聲音樣本
- 名曲與名家導聆
- 入門課程、測驗與本機學習進度
- 收藏樂器與今日練習路線
- Pro 進階聽辨與練習功能

隱私設計：

- 不需登入
- 無廣告
- 無第三方追蹤
- 學習紀錄只儲存在裝置本機

## Keywords

國樂,華樂,中國樂器,二胡,琵琶,古箏,笛子,嗩吶,音樂教育,聽辨

## Copyright

Copyright © 2026 Yu Shiung Jiang

## In-App Purchase

- Type: Non-Consumable
- Reference Name: 國樂團練習室 Pro
- Product ID: com.yuhsiangjiang.GuoYueZhiPu.pro
- Display Name zh-Hant: 國樂團練習室 Pro
- Description zh-Hant: 解鎖專家聽辨題庫、個人化練習路線、舞台編制分析與完整離線聲音包訓練提示。
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

國樂團練習室是一款離線國樂教育 App。App 內容、樂器插圖與樂器聲音樣本皆為本專案原創生成，不包含第三方授權圖片或第三方音訊。

App 不需要登入，不收集個人資料，不使用廣告 SDK，不使用第三方分析 SDK。學習進度、收藏與測驗紀錄僅透過 UserDefaults 儲存在使用者裝置本機。

Pro 付費功能使用 Apple StoreKit：

- Product ID: com.yuhsiangjiang.GuoYueZhiPu.pro
- Type: Non-Consumable
- Unlock name: 國樂團練習室 Pro

若審查環境尚未載入商品，App 會顯示「尚未連到 App Store Connect 商品」並保留恢復購買入口，不會閃退或阻擋免費內容。

## Demo Flow

1. 開啟 App 後進入「總覽」。
2. 點選「樂器」查看 23 件樂器原創插圖。
3. 任選樂器，點選「試聽離線聲音」。
4. 回到「練功」，查看課程、測驗與 Pro 進階訓練預覽。
5. 前往「Pro」頁查看 StoreKit 解鎖入口與恢復購買。

## Export Compliance

- Uses encryption: No custom encryption.
- Uses HTTPS / StoreKit only through Apple system frameworks.

## Content Rights

- App content: Original local educational dataset.
- Instrument artwork: Original generated image assets bundled in the project.
- Audio: Original generated WAV samples bundled in the project.
- Third-party media: None bundled.

## fastlane Lanes

- `fastlane ios validate_local`
- `fastlane ios upload_metadata`
- `fastlane ios build_ipa`
- `fastlane ios upload_ipa`
- `fastlane ios release_candidate`
- `CONFIRM_SUBMIT_FOR_REVIEW=yes fastlane ios submit_review`
