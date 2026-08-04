# 第一批專業者交付包

日期：2026-06-15

用途：一次交給國樂演奏者、老師、樂團行政或審核者，用來補齊最容易被專業使用者抓包的聲音與圖片。這份文件是工作包，不是通過證明；正式進 App 仍必須跑匯入與嚴格 gate。

## 第一批 7 件

- 二胡 `erhu`
- 高胡 `gaohu`
- 中胡 `zhonghu`
- 革胡 `gehu`
- 笙 `sheng`
- 嗩吶 `suona`
- 板胡 `banhu`

其中笙已有 approved 來源，但仍列入 reverify；其餘 6 件需要新的真實錄音。

## 錄音交付

正式錄音請放入：

```text
Design/Source/VerifiedAudio/inbox/full/<instrument_id>/
```

笙複審或新錄音請放入：

```text
Design/Source/VerifiedAudio/inbox/reverify/sheng/
```

每件樂器至少 3 個 take，每個 take 至少 6 秒乾淨聲音，建議 10 秒。格式為 WAV 或 AIFF，44.1 kHz 或 48 kHz，24-bit 優先；不要加混響、EQ、壓縮、背景音樂、節拍器或降噪處理。

禁止來源：

- Suno / AI-generated instrument tone
- VST、sample library、MIDI 或電子合成音色
- YouTube、CD、串流、教學影片或現場影片擷取
- pitch-shift 或 time-stretch 的相鄰樂器
- 未確認作曲權的受保護旋律

每件樂器需附 release JSON，範本在：

```text
Design/Source/VerifiedAudio/procurement/priority1_release_templates/<instrument_id>.release.template.json
```

release 必須確認：真實樂器錄音、可商用 App 散布、可剪輯轉檔、全球永久使用、非 AI、非 VST/sample library、非串流或影片擷取。

## 圖片審核

候選圖在：

```text
Design/Review/ArtworkCandidates/candidate_<instrument_id>.png
```

請只審核無圖內標註的 900x900 單張候選圖。`candidate_<instrument_id>_annotated_reference.png` 只供內部討論，不得批准匯入 App。

審核者需同步看：

- `Design/Source/InstrumentReferenceAudit/professional_visual_review_cards.json`
- `Design/Source/InstrumentReferenceAudit/high_risk_artwork_morphology_specs.json`
- `Design/Review/ArtworkCandidates/approval_drafts/<instrument_id>.approval.draft.json`

核心退回條件：

- 革胡像普通大提琴或放大二胡。
- 嗩吶像小號、薩克斯風、單簧管或西式雙簧管。
- 笙像排簫、管風琴或隨機竹管束，且沒有風箱/吹嘴。
- 板胡只是二胡換標籤，沒有木質音板或椰殼/木質共鳴體。
- 二胡、高胡、中胡只靠文字不同，琴筒大小與音域角色不可辨識。
- 圖中有錯字、浮水印、callout、英文/中文標籤或幻想結構。

## 通過後匯入

錄音先 dry-run：

```bash
python3 fastlane/scripts/import_verified_audio.py \
  --instrument-id erhu \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take1_open_string_or_sustained_tone.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take2_expressive_slide.wav \
  --source Design/Source/VerifiedAudio/inbox/full/erhu/erhu_take3_original_short_phrase.wav \
  --release Design/Source/VerifiedAudio/inbox/full/erhu/erhu.release.json
```

圖片先 dry-run：

```bash
python3 fastlane/scripts/import_approved_artwork.py \
  --instrument-id suona \
  --candidate Design/Review/ArtworkCandidates/candidate_suona.png \
  --approval Design/Review/ArtworkCandidates/approvals/suona.approval.json
```

只有 dry-run、授權、專業審聽、圖片 approval 都通過後，才能加 `--approve`。通過前不能重截最終 iPhone 6.9 / iPad 13 送審截圖。

## 機器驗證

本交付包 manifest：

```text
Design/Review/Phase1ProfessionalHandoff/phase1_professional_handoff_manifest.json
```

檢查：

```bash
python3 fastlane/scripts/check_phase1_professional_handoff.py
python3 fastlane/scripts/check_phase1_handoff_export.py
python3 fastlane/scripts/check_phase1_recording_inbox.py
python3 fastlane/scripts/import_recording_inbox_batch.py --pack priority1
```

這個檢查只證明交付包完整，不代表素材已完成。

## 匯出外部交付包

要整理成可交給演奏者或圖片審核者的資料夾與 zip，執行：

```bash
python3 fastlane/scripts/export_phase1_handoff_package.py
```

輸出位置：

```text
Build/Phase1ProfessionalHandoff/guoyue-phase1-real-audio-artwork-handoff/
Build/Phase1ProfessionalHandoff/guoyue-phase1-real-audio-artwork-handoff.zip
```

匯出的 zip 是 work packet，not approval evidence。它只包含第一批錄音與圖片審核所需文件、release templates、候選圖與 approval drafts，不包含 App Store Connect 金鑰、`.env`、`.p8`、`.git` 或任何可用來送審的私密資料。收到外部錄音與專業審核後，仍要回到 repo 內跑 inbox、審聽、圖片 approval、StoreKit、截圖與嚴格 readiness gate。
