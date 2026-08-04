# Fastlane 與 Xcode Cloud 認證

本專案的 release binary 只能由 Xcode Cloud `Archive - iOS` 產生。Fastlane 只負責 metadata、截圖、選取已經成為 `VALID` 的 Cloud build 與送審，不包含建置或上傳 IPA 的 lane。

## App Store Connect API Key

```sh
export ASC_KEY_ID="WZBYHD6QVD"
export ASC_ISSUER_ID="69a6de78-ba5a-47e3-e053-5b8c7c11a4d1"
export ASC_KEY_FILE="/Users/jushiung/Downloads/AuthKey_WZBYHD6QVD.p8"
fastlane ios prepare_cloud_submission
```

`fastlane/Fastfile` 也相容 `ASC_API_KEY_ID`、`ASC_API_KEY_PATH`、`APP_STORE_CONNECT_API_KEY_ID`、`APP_STORE_CONNECT_API_KEY_PATH`。

`upload_metadata` 與 `prepare_cloud_submission` 都會先執行嚴格送審閘門；缺素材、專業審核、IAP 附加、最終截圖或 Git push 時不會改動 App Store metadata。

## 送審已有 Cloud build

先在 App Store Connect 延遲重新查證指定 build 已為 `VALID` 且可選，再執行：

```sh
export ASC_BUILD_NUMBER="精確的 Xcode Cloud build number"
export CONFIRM_SUBMIT_FOR_REVIEW="yes"
fastlane ios submit_review
```

不要把 `.p8` 私鑰內容、Apple ID password 或 app-specific password 提交到 repo。`.env.fastlane` 只允許放固定 ID 與私鑰路徑。
