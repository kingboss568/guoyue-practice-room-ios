# 樂器圖片專業審核流程

日期：2026-06-15

## 目的

這個 App 面向國樂專業演奏者，樂器圖片不能只是「看起來像樂器」。革胡、嗩吶、笙、板胡、二胡、高胡、中胡這 7 件高風險圖片必須先通過專業審核，才能替換正式 App asset 並用於重新上架截圖。

## 審核資料

- 候選圖：`Design/Review/ArtworkCandidates/`
- 候選圖總表：`Design/Review/ArtworkCandidates/candidate_manifest.json`
- 形制規格：`Design/Source/InstrumentReferenceAudit/high_risk_artwork_morphology_specs.json`
- 專業評分表：`Design/Source/InstrumentReferenceAudit/high_risk_artwork_review_scorecard.json`
- 逐樂器審核 draft：`Design/Review/ArtworkCandidates/approval_drafts/<instrument_id>.approval.draft.json`

## 評分規則

每張圖至少要由 1 位國樂相關專業者審核，建議 2 位。審核者可為演奏家、指揮、教師、製琴/修琴師或熟悉國樂團編制的行政。

每項滿分 5 分，所有項目不得低於 4 分，平均不得低於 4.25 分：

- 樂器辨識：不看文字也能辨識是該樂器。
- 形制正確：琴筒、簧管、吹嘴、弓弦、喇叭口、共鳴箱等特徵正確。
- 相近樂器差異：尤其二胡、高胡、中胡、板胡、革胡不可混淆。
- 小尺寸可讀性：App 小卡片與 App Store 截圖尺寸仍看得出關鍵特徵。
- 無幻想細節：不可有科幻、奇幻、西式替代品或不可能構造。
- 商店適用：乾淨、單一樂器、無誤導、可放入審查版本。
- 無圖內標註：正式候選圖不得含英文/中文 callout、浮水印、說明字或任何內嵌標籤；approval JSON 必須確認 `no_visible_internal_text_labels`。

## 7 件高風險審核重點

- 革胡：必須是大型低音拉弦樂器，不可像放大的二胡，也不可只是西洋大提琴。
- 嗩吶：必須有木質錐形管身、雙簧/芯子、指孔與金屬喇叭口，不可像小號、薩克斯風或西式雙簧管。
- 笙：必須有多根簧管插入斗子，且看得到吹嘴，不可像排簫或隨機竹管束。
- 板胡：必須看得出板面或椰殼/木質小共鳴體，不可只是一般二胡換標籤。
- 二胡：作為胡琴族中間參考尺寸，需有二弦、弓毛在弦間、小型蟒皮琴筒。
- 高胡：要比二胡更小、更高音域、更輕巧，不可只是同尺寸二胡。
- 中胡：要比二胡更大、更低音域，但不可變成革胡尺度。

## 通過後匯入

專業者確認後，將對應 draft 複製到：

```text
Design/Review/ArtworkCandidates/approvals/<instrument_id>.approval.json
```

填完審核者姓名、角色、日期、組織、分數與備註，移除 `TO_BE_FILLED`，並確保 `draft_only` 不再是 `true`。

先執行 dry-run：

```bash
python3 fastlane/scripts/import_approved_artwork.py \
  --instrument-id suona \
  --candidate Design/Review/ArtworkCandidates/candidate_suona.png \
  --approval Design/Review/ArtworkCandidates/approvals/suona.approval.json
```

dry-run 通過且人工確認後，才可執行：

```bash
python3 fastlane/scripts/import_approved_artwork.py \
  --instrument-id suona \
  --candidate Design/Review/ArtworkCandidates/candidate_suona.png \
  --approval Design/Review/ArtworkCandidates/approvals/suona.approval.json \
  --approve
```

只有 `import_approved_artwork.py --approve` 完成後，候選圖才算正式進入 App。通過前不得重截最終 iPhone 6.9 / iPad 13 送審截圖。
