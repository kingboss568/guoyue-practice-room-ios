# 國樂實器錄音採購規格

日期：2026-06-15

## 目的

本 App 的核心問題不是缺音效，而是專業演奏者會立即聽出假音色。方案 A 採「真實演奏錄音優先」：優先向演奏者、樂團或錄音師取得短句與單音錄音；公開素材只在原始錄音、授權與樂器真實性都能確認時使用。

## Suno / AI 音樂使用判斷

Suno 或其他 AI 音樂生成工具不作為 23 件樂器音檔來源。即使付費方案可能授予商業使用權，AI 生成音色仍不能證明是真實樂器演奏，且專業國樂使用者容易聽出錯誤的起音、揉弦、氣口、共鳴與演奏習慣。

可接受的有限用途：

- 內部 demo 或臨時排版測試，不進正式 App bundle。
- 非核心、明確標示為 AI 生成的背景氣氛草稿，且不得宣稱為實器錄音。
- 產生錄音採購用的「節奏/長度參考」，但最終仍必須由真人實器重錄。

不可接受的用途：

- 用 Suno 生成二胡、高胡、中胡、笙、嗩吶、革胡等樂器樣本。
- 把 AI 音色剪成單音後放入 `GuoYueZhiPu/Resources/Audio/Instruments/`。
- 在 App Store metadata、paywall 或 review notes 宣稱 AI 音檔為真實國樂樂器聲音。

## 交付格式

- 原始交付：WAV 或 AIFF，48 kHz 或 44.1 kHz，24-bit 優先。
- App 版 master：mono、44.1 kHz、16-bit WAV。
- 每件樂器至少 6 秒乾淨內容，10 秒以上較佳。
- 前後各留 0.5 秒 room tone，方便降噪與淡入淡出。
- 不加混響、壓縮、EQ、背景音樂或節拍器。
- 一件樂器一個資料夾，檔名格式：`<instrument_id>_<take>_<description>.wav`。

## 錄音內容

吹管：

- 笙：長和音、單管音、短琶音。
- 嗩吶：長音、短裝飾、強起音。
- 簫：氣息長音、短下行句。
- 管子：雙簧長音、短樂句。

彈撥：

- 琵琶：單音、輪指色彩、短句。
- 古箏：單音、刮奏或滑音、短句。
- 揚琴：單擊、輪音、短句。
- 柳琴：單音、快速短句。
- 中阮：單音、和弦、短句。
- 三弦：單音、滑音、短句。
- 箜篌：單音、琶音、短句。

拉弦：

- 二胡：空弦或長音、滑音、短句。
- 高胡：明亮長音、粵樂感短句。
- 中胡：較低長音、抒情短句。
- 板胡：亮起音、長音、北方風格短句。
- 革胡：低音長弓、短低音手勢。

打擊：

- 編鐘：單鐘敲擊與完整衰減。
- 堂鼓：鼓心、鼓邊、短滾奏。
- 鑼：單擊與完整衰減。
- 鈸：開鈸、悶鈸、輕擊。
- 木魚：單擊與短節奏。
- 排鼓：至少三個鼓高、短滾奏。

## 授權條款底線

授權文件必須明確允許：

- 用於 `國樂團練習室` iOS App 與其後續版本。
- 商業販售、訂閱或 IAP 內使用。
- 剪輯、降噪、音量正規化、轉檔。
- 全球、永久、不可撤回使用。
- App Store、官方網站、行銷截圖與審查資料中呈現。

不可接受：

- 僅限個人使用、非商業使用、教育用途限定。
- 只授權影片/廣告但不授權 App 內散布。
- 來源其實是 VST、sample library、AI 生成或未授權翻錄。
- 曲目仍受著作權保護且未取得音樂著作授權。

## 驗收

每件樂器進入 App 前，必須完成：

- 原始音檔與授權文件存檔。
- `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json` 增加 `approved` 條目。
- 轉檔到 `Design/Source/VerifiedAudio/Instruments/<instrument_id>.wav`。
- 同步到 `GuoYueZhiPu/Resources/Audio/Instruments/<instrument_id>.wav`。
- `python3 fastlane/scripts/check_asset_authenticity.py --strict` 對該樂器通過。

目前採購追蹤表：`Design/Source/VerifiedAudio/procurement/audio_procurement_tracker.json`。

可直接對外使用的委託包：`Docs/AssetLicenses/RecordingCommissionPack.zh-Hant.md`。

22 件收件 checklist：`Design/Source/VerifiedAudio/procurement/recording_delivery_checklist.json`。

## 匯入流程

新收到的錄音先放入 `Design/Source/VerifiedAudio/inbox/full/<instrument_id>/`，並依 `Design/Source/VerifiedAudio/procurement/full_release_templates/<instrument_id>.release.template.json` 填好授權 JSON。第一階段笙複審資料放入 `Design/Source/VerifiedAudio/inbox/reverify/sheng/`。

先 dry-run：

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take1_open_string_or_sustained_tone.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take2_expressive_slide.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take3_original_short_phrase.wav \
  --release Design/Source/VerifiedAudio/inbox/full/erhu/erhu.release.json
```

確認音檔、授權與轉檔資訊無誤後，才正式匯入：

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take1_open_string_or_sustained_tone.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take2_expressive_slide.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take3_original_short_phrase.wav \
  --release Design/Source/VerifiedAudio/inbox/full/erhu/erhu.release.json \
  --approve
```

正式匯入會同時更新：

- `Design/Source/VerifiedAudio/originals/`
- `Design/Source/VerifiedAudio/releases/`
- `Design/Source/VerifiedAudio/Instruments/<instrument_id>.wav`
- `GuoYueZhiPu/Resources/Audio/Instruments/<instrument_id>.wav`
- `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json`
