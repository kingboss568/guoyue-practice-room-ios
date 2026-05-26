# fastlane 上傳認證

目前 `fastlane ios upload_ipa` 已可用兩種認證方式。本專案已依上層固定規範加入 `.env.fastlane`，只記錄 App Store Connect API Key ID、Issuer ID 與 `.p8` 私鑰路徑，不包含私鑰內容。

## 建議方式：App Store Connect API Key

設定下列環境變數後即可上傳：

```sh
export ASC_KEY_ID="WZBYHD6QVD"
export ASC_ISSUER_ID="69a6de78-ba5a-47e3-e053-5b8c7c11a4d1"
export ASC_KEY_FILE="/Volumes/Crucial X6/@CodexAPP 13套戰略/永久列管/AuthKey_WZBYHD6QVD.p8"
fastlane ios upload_ipa
```

`fastlane/Fastfile` 也保留相容舊環境變數：`ASC_API_KEY_ID`、`ASC_API_KEY_PATH`、`APP_STORE_CONNECT_API_KEY_ID`、`APP_STORE_CONNECT_API_KEY_PATH`。

## 備用方式：Apple ID App-Specific Password

若不用 API key，需要提供 Apple ID 與 app-specific password：

```sh
export FASTLANE_USER="jushiung@gmail.com"
export FASTLANE_PASSWORD="你的 app-specific password"
fastlane ios upload_ipa
```

不要把 `.p8` 私鑰內容、Apple ID password 或 app-specific password 提交到 repo。`.env.fastlane` 只允許放固定 ID 與私鑰路徑。
