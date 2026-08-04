# 第一階段實器錄音委託訊息

日期：2026-06-15

用途：可直接寄給國樂演奏者、樂團助理或錄音協力者，用來收第一批高風險實器音檔。

## 委託內容

我們正在更新 iOS App「國樂團練習室」，需要可商用、可稽核、可讓專業國樂演奏者辨識為真實樂器的短錄音。

第一階段優先收：

- 二胡
- 高胡
- 中胡
- 革胡
- 嗩吶
- 板胡
- 笙複審資料或新錄音

其中二胡、高胡、中胡、革胡、嗩吶、板胡是目前缺正式 approved 音源的項目；笙已有來源，但仍需要專業複審，避免聽感被誤認為 accordion、harmonica 或 synth pad。

## 錄音需求

每件樂器請交 3 個 take，每個 take 至少 6 秒乾淨可用聲音，建議 10 秒。

請錄：

- 一段代表性長音或單音。
- 一段能表現該樂器技法的短 gesture。
- 一段原創短句，不使用仍受著作權保護的旋律。

請不要加入混響、EQ、壓縮、降噪、修音、節拍器、伴奏或背景音樂。

## 檔案格式

- WAV 或 AIFF。
- 44.1 kHz 或 48 kHz。
- 24-bit 優先。
- mono 或 stereo 都可以，App 端會另外轉成 mono 44.1 kHz 16-bit WAV。

## 授權確認

請一併提供授權資訊，需明確允許：

- 用於「國樂團練習室」iOS App 與後續版本。
- 商業 App、IAP 或付費功能內使用。
- 剪輯、轉檔、音量調整與格式轉換。
- 全球、永久使用。
- 在 App Store 審查資料、App 內來源頁與支援文件中列出來源。

## 一律拒收

下列來源不可使用：

- Suno、Udio、MusicGen、Stable Audio 或其他生成式音樂。
- AI-generated instrument tone。
- VST、sample library、MIDI、synthesizer、GarageBand 音色。
- YouTube、Spotify、Apple Music、CD、串流或社群影片擷取。
- 不明演奏者、不明授權、背景音樂、環境噪音壓過主樂器。

即使生成音樂服務標示可商用，也不能當成國樂實器錄音。這批素材是給專業演奏者使用的練習 App，音色必須能被專業者聽得過。

## 收件資料夾

專案內收件位置：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

笙複審資料：

```text
Design/Source/VerifiedAudio/inbox/reverify/sheng/
```

詳細檔名與 take 規格以這份 manifest 為準：

```text
Design/Source/VerifiedAudio/procurement/priority1_recording_delivery_pack.json
```
