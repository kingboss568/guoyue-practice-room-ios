# 演奏者錄音工作單與專業審聽門檻

日期：2026-08-04

這份工作單是給未來的真實國樂演奏者、錄音協力者與專業審聽者使用。它是 1.1 上架後逐步把「原站示範」升級成可合法內建音源的採購規格，不是用假審核紀錄填滿 App，也不是本次送審的必要條件。

## 第一階段優先錄音

優先處理專業者最容易聽出假的項目：

| 樂器 | 原因 |
| --- | --- |
| 中胡 | 不能用二胡降音或 cello/bass 替代 |
| 革胡 | 不能用西洋 cello 或 synth strings 替代 |

高胡已取得 Wikimedia Commons《連環扣》的真人獨奏與商用授權，不再列為缺件。7 件外部參考缺口是管子、箜篌、中胡、革胡、編鐘、堂鼓、排鼓；中胡、革胡列第一階段，管子、箜篌列第二階段，編鐘、堂鼓、排鼓列第三階段。

目前 16 件內建 WAV 已由原始來源或資料集明確標示實器與樂器身分，並完成商用授權、作者、雜湊與格式稽核；不建立不存在的具名審聽紀錄。若日後收到新委託錄音，仍必須依本工作單進行真人專業審聽後才能取代現有來源。

未來審聽的高風險互相比對仍保留二胡、高胡、中胡、板胡、革胡、嗩吶與笙，避免新錄音把相鄰胡琴、雙簧管音色或合成墊音誤判為目標樂器。

## 交付格式

每件樂器至少交付三個 take，檔名以 `full_open_recording_delivery_pack.json` 為準。每個 take 至少 6 秒乾淨可用聲音，建議 10 秒。

錄音格式：

- WAV 或 AIFF。
- 44.1 kHz 或 48 kHz。
- 24-bit 優先。
- 不加混響、EQ、壓縮、降噪、修音、伴奏或背景音樂。
- 可 mono 或 stereo；App 內 master 會轉成 mono 44.1 kHz 16-bit WAV。

交付位置：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

若日後主動安排既有音檔的額外複審資料，可依樂器放在：

```text
Design/Source/VerifiedAudio/inbox/reverify/<instrument_id>/
```

每件樂器還要附：

```text
<instrument_id>.release.json
```

release 必須確認真實樂器錄音、可商用 App 散布、允許剪輯轉檔、全球永久使用、不是 AI/VST/sample library，也不是 YouTube/CD/串流擷取。

## 審聽評分

正式匯入前，至少一位國樂專業者完成 `professional_listening_review_scorecard.json`。建議兩位。

每項 1 到 5 分，單項至少 4 分，平均至少 4.25 分：

- 樂器辨識正確。
- 專業音色可信。
- 技法代表性。
- 錄音乾淨度。
- 適合練習室訓練。

未通過審聽不得執行 `import_verified_audio.py --approve`，也不得在 StoreKit paywall 或 App Store metadata 宣稱完整真實聲音包。

審聽紀錄要填在：

```text
Design/Source/VerifiedAudio/procurement/professional_listening_review_scorecard.json
```

decision 必須是 `approved_for_import`，且每項分數不得低於 4、平均不得低於 4.25。需要批次檢查或匯入時使用：

```bash
python3 fastlane/scripts/check_professional_listening_scorecard.py
python3 fastlane/scripts/import_recording_inbox_batch.py --instrument-id erhu
python3 fastlane/scripts/import_recording_inbox_batch.py --instrument-id erhu --approve
```

## 驗證指令

```bash
python3 fastlane/scripts/check_recording_work_order.py
python3 fastlane/scripts/check_full_open_recording_pack.py
python3 fastlane/scripts/check_professional_listening_scorecard.py
STRICT_READY=0 bash fastlane/scripts/validate_submission_ready.sh
```

送審前仍要跑嚴格 gate：

```bash
STRICT_READY=1 bash fastlane/scripts/validate_submission_ready.sh
```

嚴格 gate 會驗證 16 件內建 WAV 的來源、商用授權、雜湊與格式，以及 7 件外部參考均未被包入或加入付費題庫；委託錄音與專業審聽表只在實際收到新錄音時才成為匯入門檻。
