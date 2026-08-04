# 國樂團練習室實器錄音委託包

日期：2026-06-15

## 可直接發給演奏者 / 樂團的訊息

您好，我們正在為 iOS App「國樂團練習室」重新製作國樂樂器音檔。這個 App 的使用者包含國樂演奏者、教師與進階學習者，所以音檔必須是真實樂器錄音，不接受 AI 生成、VST、sample library 或網路擷取音檔。

想委託您錄製指定樂器的短音檔，每件樂器約 3 到 5 個 take，每個 take 6 到 12 秒。內容以單音、長音、代表性技法或短即興句為主，避免使用仍受著作權保護的曲目。錄音會用於 App 內播放、App Store 審查資料、截圖/預覽與官方宣傳素材。

我們需要一份授權確認，內容包含：可商業 App 內散布、可剪輯/降噪/轉檔、全球永久使用、錄音為真實樂器演奏，且未使用 AI/VST/未授權音源。若您方便，我們會提供簡短授權同意書範本。

交付格式希望是 WAV 或 AIFF，44.1 kHz 或 48 kHz，24-bit 優先；請不要加混響、壓縮、EQ、背景音樂或節拍器。

## 交付檔案

每件樂器請提供：

- 原始錄音 WAV / AIFF。
- 授權同意書或授權 JSON。
- 錄音日期、錄音地點、演奏者/單位名稱。
- 若內容包含特定曲目，需提供曲名、作曲者與著作權狀態；未確認前不放入 App。

## 檔名範例

- `erhu_take1_open_string.wav`
- `erhu_take2_slide_phrase.wav`
- `sheng_take1_long_chord.wav`
- `suona_take1_strong_attack.wav`
- `luo_take1_full_decay.wav`

## 第一優先：專業者最容易聽出假的 7 件

逐件檔名、take 內容、拒收條件與 release JSON 範本已整理在 `Design/Source/VerifiedAudio/procurement/priority1_recording_delivery_pack.json`，說明文件見 `Docs/AssetLicenses/Priority1RecordingDeliveryPack.zh-Hant.md`。

完整剩餘 open 樂器交付包已整理在 `Design/Source/VerifiedAudio/procurement/full_open_recording_delivery_pack.json`，說明文件見 `Docs/AssetLicenses/FullOpenRecordingDeliveryPack.zh-Hant.md`。正式送審前，21 件 open 樂器都必須通過實器錄音、授權與專業審聽 gate，不能用 Suno、生成式音樂、VST、sample library 或網路擷取音檔補位。

| 樂器 | 錄音內容 |
| --- | --- |
| 二胡 | 空弦或長音、滑音、短句 |
| 高胡 | 明亮長音、粵樂感短句 |
| 中胡 | 較低長音、抒情短句 |
| 革胡 | 低音長弓、短低音手勢 |
| 笙 | 長和音、單管音、短琶音 |
| 嗩吶 | 長音、短裝飾、強起音 |
| 板胡 | 亮起音、長音、北方風格短句 |

## 第二優先：核心聲部覆蓋 9 件

| 樂器 | 錄音內容 |
| --- | --- |
| 簫 | 氣息長音、短下行句 |
| 管子 | 雙簧長音、短樂句 |
| 琵琶 | 單音、輪指色彩、短句 |
| 古箏 | 單音、刮奏或滑音、短句 |
| 揚琴 | 單擊、輪音、短句 |
| 柳琴 | 單音、快速短句 |
| 中阮 | 單音、和弦、短句 |
| 三弦 | 單音、滑音、短句 |
| 箜篌 | 單音、琶音、短句 |

## 第三優先：打擊補齊 6 件

| 樂器 | 錄音內容 |
| --- | --- |
| 編鐘 | 單鐘敲擊與完整衰減 |
| 堂鼓 | 鼓心、鼓邊、短滾奏 |
| 鑼 | 單擊與完整衰減 |
| 鈸 | 開鈸、悶鈸、輕擊 |
| 木魚 | 單擊與短節奏 |
| 排鼓 | 至少三個鼓高、短滾奏 |

## 內部匯入檢查

收到音檔後，先放入 `Design/Source/VerifiedAudio/inbox/`，填好 `release_template.json`，再執行：

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/erhu_take1_open_string.wav \
  --source Design/Source/VerifiedAudio/inbox/erhu_take2_slide_phrase.wav \
  --source Design/Source/VerifiedAudio/inbox/erhu_take3_original_phrase.wav \
  --release Design/Source/VerifiedAudio/inbox/erhu.release.json
```

`--source` 可重複多次。dry-run 會先把每個 take 轉成 mono 44.1 kHz 16-bit WAV，再串成一個 App master 供審聽；通過授權、音質與專業聽辨後才加 `--approve` 匯入正式 App 資源。
