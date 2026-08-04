# IAP Setup

The product already exists in App Store Connect and is APPROVED. On 2026-08-04 a conservative zh-Hant localization was created through the controlled App Store Connect UI and verified through the API; it remains `PREPARE_FOR_SUBMISSION` and must be included with version 1.1 only after asset gates pass.

## Product

- Type: Non-Consumable
- Reference Name: 國樂團練習室 Pro
- Product ID: `com.yuhsiangjiang.GuoYueZhiPu.pro`
- Display Name zh-Hant: 國樂團練習室 Pro
- Description zh-Hant: 解鎖23種樂器各50題、230題基礎知識與已授權實器聽辨；一次購買並支援恢復。
- Suggested price: NT$190

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
- IAP type/state: `NON_CONSUMABLE`, `APPROVED`.
- Price schedule exists.
- zh-Hant display name matches: `國樂團練習室 Pro`.
- The old approved localization still contains obsolete claims. Apple rejected direct API modification because that record is ACTIVE.
- The controlled App Store Connect UI successfully created a second zh-Hant localization with the conservative wording. It is `PREPARE_FOR_SUBMISSION`, and the API now reports an exact match to `fastlane/iap/products.json`.
- The IAP review-notes field still displays the obsolete copy; an attempted edit reverted on the approved product surface. Replace it on the editable 1.1 review surface before submission.
- Current live app version returned by API is `1.0`, state `READY_FOR_SALE`; this redesign is version `1.1`, whose editable version page still needs the IAP attachment in App Store Connect.

## Paywall Review Manifest

- Review manifest: `fastlane/iap/paywall_review_manifest.json`
- Local validation: `python3 fastlane/scripts/check_storekit_paywall.py`
- App Store Connect read-only verification: `ruby fastlane/scripts/verify_asc_iap.rb`
- Strict validation fails until the approved IAP and the new zh-Hant localization are attached to version 1.1, the obsolete IAP review note is replaced, and the final Pro/payment screenshot is recaptured after verified audio and artwork gates pass.

## fastlane 注意事項

- `fastlane deliver` 不會建立 IAP 產品。
- 送審前需在 App Store Connect 確認 `com.yuhsiangjiang.GuoYueZhiPu.pro` 維持 APPROVED、價格存在、zh-Hant localization 不宣稱未完成聲音包；等實器音檔與圖片審核 gate 通過後，附上新版 review screenshot，並將此 IAP 加到目前 App version 的審查項目。
- 本 repo 的 IAP manifest 位於 `fastlane/iap/products.json`，用於讓 product ID、名稱、描述與程式碼保持一致。
- `verify_asc_iap.rb` 預設只讀取 ASC 狀態，不建立或修改 IAP；它會輸出 `fastlane/iap/asc_iap_verification.json`。若要把已驗證的 product/localization/price 狀態同步到 paywall manifest，可加 `--update-manifest`，但 version-page IAP 附掛仍需 Comet 受控 tab 最後確認。
- `--fix-localization` 只適合可編輯的 localization。既有 ACTIVE 繁中紀錄不可由 API 修改；2026-08-04 已透過受控 ASC UI 建立正確的新繁中紀錄，最終需將其與 IAP 一起附加到 1.1 審查。
