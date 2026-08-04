# IAP Setup

The product already exists in App Store Connect. On 2026-08-04 a conservative zh-Hant localization was created through the controlled App Store Connect UI and verified through the API. It was attached to App `1.1 (2)` and submitted together in review submission `e206011f-7c63-4729-9070-a112a91178f2`; both submitted items are now `WAITING_FOR_REVIEW`.

## Product

- Type: Non-Consumable
- Reference Name: 國樂團練習室 Pro
- Product ID: `com.yuhsiangjiang.GuoYueZhiPu.pro`
- Display Name zh-Hant: 國樂團練習室 Pro
- Description zh-Hant: 解鎖23種樂器各50題、230題基礎知識與已授權實器聽辨；一次購買並支援恢復。
- Suggested price: NT$190
- StoreKit price observed in the current test storefront: $5.99

## App Store Connect Privacy

- Data collection: No data collected
- Tracking: No
- Third-party advertising: No
- Third-party analytics: No

## Review Dependency

The app handles missing products gracefully, but paid unlock must be created and attached to the version before final submission.

## Live ASC Verification 2026-08-04

Read-only verification command:

```bash
ruby fastlane/scripts/verify_asc_iap.rb --update-manifest
```

Evidence file: `fastlane/iap/asc_iap_verification.json`.

Current verified state:

- App Store Connect app found: `國樂團練習室`, app id `6772708738`.
- IAP product found: `com.yuhsiangjiang.GuoYueZhiPu.pro`, ASC IAP id `6773302182`.
- IAP type: `NON_CONSUMABLE`.
- Price schedule exists.
- zh-Hant display name matches: `國樂團練習室 Pro`.
- The controlled App Store Connect UI created and selected the conservative zh-Hant wording that exactly matches `fastlane/iap/products.json`.
- The version-level review notes now describe the real free trial, StoreKit product, purchase/restore controls, Demo flow, and third-party media licensing.
- App `1.1 (2)` and this IAP were submitted as two items in submission `e206011f-7c63-4729-9070-a112a91178f2`; the submission, App version, and both visible review items are `WAITING_FOR_REVIEW`.

## Paywall Review Manifest

- Review manifest: `fastlane/iap/paywall_review_manifest.json`
- Local validation: `python3 fastlane/scripts/check_storekit_paywall.py`
- App Store Connect read-only verification: `ruby fastlane/scripts/verify_asc_iap.rb`
- Strict validation passed before submission; the IAP, zh-Hant localization, and final Pro/payment screenshots are attached to version `1.1 (2)`.

## fastlane 注意事項

- `fastlane deliver` 不會建立 IAP 產品。
- 本次已確認 `com.yuhsiangjiang.GuoYueZhiPu.pro` 價格存在、zh-Hant localization 不宣稱未完成聲音包，且新版 review screenshot 已和 App `1.1 (2)` 一起送審。
- 本 repo 的 IAP manifest 位於 `fastlane/iap/products.json`，用於讓 product ID、名稱、描述與程式碼保持一致。
- `verify_asc_iap.rb` 預設只讀取 ASC 狀態，不建立或修改 IAP；它會輸出 `fastlane/iap/asc_iap_verification.json`。若要把已驗證的 product/localization/price 狀態同步到 paywall manifest，可加 `--update-manifest`，但 version-page IAP 附掛仍需 Comet 受控 tab 最後確認。
- `--fix-localization` 只適合可編輯的 localization。既有 ACTIVE 繁中紀錄不可由 API 修改；本次使用受控 ASC UI 的正確繁中紀錄，並已隨 IAP 與 App `1.1 (2)` 送審。
