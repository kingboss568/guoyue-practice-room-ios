# fastlane 上傳認證

目前 `fastlane ios upload_ipa` 已可用兩種認證方式。

## 建議方式：App Store Connect API Key

設定下列環境變數後即可上傳：

```sh
export ASC_API_KEY_ID="你的 Key ID"
export ASC_ISSUER_ID="你的 Issuer ID"
export ASC_API_KEY_PATH="/absolute/path/AuthKey_XXXXXX.p8"
fastlane ios upload_ipa
```

## 備用方式：Apple ID App-Specific Password

若不用 API key，需要提供 Apple ID 與 app-specific password：

```sh
export FASTLANE_USER="jushiung@gmail.com"
export FASTLANE_PASSWORD="你的 app-specific password"
fastlane ios upload_ipa
```

不要把 `.p8`、password 或 `.env` 提交到 repo。
