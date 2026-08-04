# 樂器圖片校正計畫

日期：2026-06-15

## 原則

樂器圖不能靠幻想補細節。每張圖在重新上架前都要有「真實形制參考、問題紀錄、校正狀態」，必要時請國樂演奏者或樂團行政逐張確認。

圖片可以重做，但生成前必須先明確描述形制差異，例如革胡不是放大的二胡、嗩吶不是西式小號、笙要看得到簧管束與斗子。所有新圖仍需經人工校對後才可包入正式版。

## 優先修正

- 革胡：目前最危險，需改成大型低音拉弦樂器，接近 cello-like 演奏姿態與大型共鳴箱。
- 嗩吶：需避免西式銅管感，喇叭口、木管管身、雙簧嘴比例要正確。
- 笙：需清楚呈現多根簧管、斗子、吹嘴角度。
- 板胡：需有板面或椰殼/木質小共鳴體特徵，不可像一般二胡。
- 二胡 / 高胡 / 中胡：三者要靠琴筒大小、琴桿比例與音域角色區分，不可只換文字標籤。

## 目前分級

詳細逐項狀態在 `Design/Source/InstrumentReferenceAudit/instrument_reference_audit.json`。送審前至少要把 `needs_regeneration` 與 `needs_differentiation` 全部改成 `approved_after_review`。

## 生成提示規格

新圖 prompt 必須包含：

- 樂器中文名稱與英文名稱。
- 關鍵形制，例如「笙：多根垂直竹/金屬簧管插在斗子上，有吹嘴」。
- 不可出現的混淆，例如「嗩吶不可像 trumpet 或 saxophone」。
- 寫實產品圖或教學圖風格，避免奇幻、科幻、舞台概念圖。
- 單一樂器、乾淨背景、不可加錯誤文字，也不可加任何圖內 callout、浮水印或說明標籤。

生成後檢查：

- 形制是否正確。
- 常見錯認是否排除。
- 圖像是否能在 900x900 與 App 小卡片尺寸下辨識。
- 圖像是否不需要圖內文字也能辨識；正式 approval 必須確認 `no_visible_internal_text_labels`。
- 檔案是否替換到 `Design/Source/GeneratedInstruments/instrument_<id>.png`，再同步到 Xcode asset catalog。

## Prompt Pack

高風險樂器的重做提示已整理在 `Design/Source/InstrumentReferenceAudit/artwork_regeneration_prompts.json`。這些 prompt 只能產生候選圖，不代表通過；圖片必須經國樂專業者校對後，才能把 `instrument_reference_audit.json` 狀態改成 `approved_after_review`。

Prompt 來源必須回連到 `Design/Source/InstrumentReferenceAudit/artwork_reference_sources.json`。這份 manifest 記錄每件高風險樂器至少兩個外部參考來源、來源支撐的形制特徵、正向生成詞、禁止混淆項與不可照抄參考照片的規則。新增或修改 prompt 後必須跑：

```bash
python3 fastlane/scripts/check_artwork_reference_prompts.py
```

這個檢查會確認 prompt 的 `required_positive_terms`、`forbidden_confusions`、`must_show_checklist`、`must_not_show_checklist` 都與來源 manifest 和 morphology spec 對齊。

## 高風險形制驗收規格

革胡、嗩吶、笙、板胡、二胡、高胡、中胡另有逐項形制驗收規格：`Design/Source/InstrumentReferenceAudit/high_risk_artwork_morphology_specs.json`。這份規格列出每件樂器必須出現、不得出現、相對大小與專業審核問題。

`fastlane/scripts/check_artwork_morphology_specs.py` 已接入送審 gate：

- 非嚴格模式會確認規格完整，並提醒尚未專業審核。
- 嚴格送審模式會要求高風險樂器 audit 狀態為 `approved_after_professional_review`，且候選圖標記為 `replacement_ready`。
- `fastlane/scripts/check_artwork_reference_prompts.py` 會確認來源 manifest 與生成提示沒有脫鉤，避免產生沒有真實形制依據的幻想圖。
- `fastlane/scripts/check_artwork_visual_review_cards.py` 會確認高風險樂器都有來源支撐的專業審核卡，讓審核者逐項檢查可接受條件、退回條件與縮圖可讀性。
- `fastlane/scripts/check_artwork_review_scorecard.py` 會確認 7 件高風險圖片都有專業評分表與胡琴族/吹管/簧管差異檢查；嚴格送審模式會要求每件都有通過的專業 review record。

這代表候選圖即使尺寸正確，也不能在專業審核前直接替換正式 App 圖。

## 專業審核卡

高風險候選圖另有逐張審核卡：`Design/Source/InstrumentReferenceAudit/professional_visual_review_cards.json`，說明文件為 `Docs/InstrumentArtworkVisualReviewCards.zh-Hant.md`。審核卡把 Grinnell、Met、Britannica、Eason、Timbre and Orchestration 等來源中的形制描述轉成可勾選的 acceptance / rejection tests。

這份審核卡不能替代專業 approval；它的作用是避免圖片生成或人工審核時只看「像不像」而漏掉關鍵構造，例如嗩吶的雙簧與金屬喇叭口、笙的風箱與吹嘴、板胡的木質音板、二胡/高胡/中胡的相對大小，以及革胡的大型低音拉弦比例。

## 專業評分表

高風險圖片的專業評分表在 `Design/Source/InstrumentReferenceAudit/high_risk_artwork_review_scorecard.json`，審核說明在 `Docs/InstrumentArtworkProfessionalReview.zh-Hant.md`。

評分表要求每張圖至少 1 位國樂專業者審核，建議 2 位。每項分數不得低於 4 分，平均不得低於 4.25 分；檢查項包含樂器辨識、形制正確、相近樂器差異、小尺寸可讀性、無幻想細節與 App Store 適用性。

嚴格送審前必須跑：

```bash
python3 fastlane/scripts/check_artwork_review_scorecard.py --strict
```

若尚未填入通過的 `review_records`，嚴格模式會失敗，代表不可重截最終商店截圖、不可回報圖片已完成。

## 目前候選圖

已先產出一組 900x900 無圖內標註的形制校正候選圖，位置在 `Design/Review/ArtworkCandidates/`，總覽圖為 `Design/Review/ArtworkCandidates/candidate_contact_sheet.png`。這組候選圖只解決「明顯錯形制」的第一階段問題，例如革胡改成大型低音拉弦、笙有簧管束與斗子、嗩吶有木質錐形管身與金屬喇叭口、胡琴三件用大小比例區分。contact sheet 底下的檔名文字只作為 review index；單張 900x900 候選圖本體不得含 callout、浮水印或說明文字。

原本帶內部標註的 morphology 草稿已保留為 `candidate_<instrument_id>_annotated_reference.png`，只作為形制討論參考，不得匯入 App。

候選圖 manifest：`Design/Review/ArtworkCandidates/candidate_manifest.json`。

送審前仍需：

- 由國樂專業者逐張確認。
- 若專業者退回形制問題，重跑 `Tools/generate_textless_artwork_candidates.py` 或用同等無標註流程產生新候選圖。
- 若通過，才替換 `Design/Source/GeneratedInstruments/instrument_<id>.png`。
- 替換後更新 `Design/Source/InstrumentReferenceAudit/instrument_reference_audit.json` 為 `approved_after_professional_review`。
- 重新產生 app asset、截圖並跑嚴格 gate。

## 專業審核通過後的匯入流程

不要手工覆蓋正式圖檔。審核者確認候選圖後，先複製並填寫：

```text
Design/Review/ArtworkCandidates/approval_template.json
```

為了降低漏填風險，7 件高風險候選圖也已預先產生逐樂器 approval drafts：

```text
Design/Review/ArtworkCandidates/approval_drafts/<instrument_id>.approval.draft.json
```

每份 draft 已預填候選圖路徑、sha256、尺寸、至少兩個參考來源、`must_show`、`must_not_show`、相對比例規則與專業審核問題。draft 仍含 `TO_BE_FILLED` 並標記 `draft_only: true`，不可直接當作通過證明。交給審核者前可先跑：

```bash
python3 fastlane/scripts/check_artwork_approval_drafts.py
```

正式通過時，請把對應 draft 複製到 `Design/Review/ArtworkCandidates/approvals/<instrument_id>.approval.json`，填完審核者姓名、角色、日期、組織與筆記，移除或改掉 `draft_only`，並確認沒有 `TO_BE_FILLED` 後再 import。

填寫時必須：

- 指定 `instrument_id`、`candidate_path`、`candidate_sha256`。
- 填入審核者姓名、角色與日期。
- `reference_urls_reviewed` 至少包含本專案列出的兩個參考來源。
- `approved_must_show` 必須完整列出該樂器在 `high_risk_artwork_morphology_specs.json` 的 `must_show`。
- `rejected_must_not_show` 必須完整列出該樂器在 `high_risk_artwork_morphology_specs.json` 的 `must_not_show`。
- 所有 confirmations 必須為 true。

先 dry-run：

```bash
python3 fastlane/scripts/import_approved_artwork.py \
  --instrument-id suona \
  --candidate Design/Review/ArtworkCandidates/candidate_suona.png \
  --approval Design/Review/ArtworkCandidates/approvals/suona.approval.json
```

dry-run 通過、人工確認無誤後才加 `--approve`。approve 會同時：

- 替換 `Design/Source/GeneratedInstruments/instrument_<id>.png`。
- 替換 `GuoYueZhiPu/Assets.xcassets/instrument_<id>.imageset/instrument_<id>.png`。
- 更新候選圖 manifest 為 `replacement_ready`。
- 更新高風險 morphology spec 的 `candidate_status`。
- 更新 audit 狀態為 `approved_after_professional_review`。
- 重新產生 `GuoYueZhiPu/Models/ArtworkReview.swift`，讓 App 內圖片狀態同步。

這個流程不會讓候選圖自動通過；只有有審核 JSON 且所有形制條件都符合時才會替換正式資產。
