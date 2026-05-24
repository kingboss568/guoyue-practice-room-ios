# IAP Setup

Create this product in App Store Connect before submitting the first review build.

## Product

- Type: Non-Consumable
- Reference Name: 國樂團練習室 Pro
- Product ID: `com.yuhsiangjiang.GuoYueZhiPu.pro`
- Display Name zh-Hant: 國樂團練習室 Pro
- Description zh-Hant: 解鎖專家聽辨題庫、個人化練習路線、舞台編制分析與完整離線聲音包訓練提示。
- Suggested price: NT$190

## App Store Connect Privacy

- Data collection: No data collected
- Tracking: No
- Third-party advertising: No
- Third-party analytics: No

## Review Dependency

The app handles missing products gracefully, but paid unlock must be created and attached to the version before final submission.

## fastlane 注意事項

- `fastlane deliver` 不會建立 IAP 產品。
- 送審前需先在 App Store Connect 建立 `com.yuhsiangjiang.GuoYueZhiPu.pro`，設定價格，加入 zh-Hant localization，附上 review screenshot，並將此 IAP 加到目前 App version 的審查項目。
- 本 repo 的 IAP manifest 位於 `fastlane/iap/products.json`，用於讓 product ID、名稱、描述與程式碼保持一致。
