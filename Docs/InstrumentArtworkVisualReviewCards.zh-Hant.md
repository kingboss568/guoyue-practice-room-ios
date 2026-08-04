# 高風險樂器圖片專業審核卡

日期：2026-06-15

這份審核卡把外部來源的形制描述轉成逐張圖片的驗收問題。它不是通過證明；7 張候選圖仍需國樂專業者填 approval JSON，並由 `import_approved_artwork.py --approve` 匯入後才可替換正式 App 圖片。

## 使用方式

審核者請同時看：

- 候選圖：`Design/Review/ArtworkCandidates/candidate_<instrument_id>.png`
- 規格：`Design/Source/InstrumentReferenceAudit/high_risk_artwork_morphology_specs.json`
- 審核卡：`Design/Source/InstrumentReferenceAudit/professional_visual_review_cards.json`
- approval draft：`Design/Review/ArtworkCandidates/approval_drafts/<instrument_id>.approval.draft.json`

每件樂器都要確認：

- 不看文字也能辨識。
- 不會和相鄰樂器混淆。
- 不含幻想、科幻、錯誤材質或西洋替代樂器。
- 小尺寸仍看得到關鍵構造。
- 沒有圖內標籤、浮水印、callout 或錯字。

## 關鍵來源摘要

- 嗩吶：Grinnell 描述其為中國 double-reed shawm，含木質錐形管、指孔、金屬喇叭口、bocal/staple 與小雙簧。
- 笙：Grinnell 描述其為 free-reed mouth organ，管束插入木質碗狀風箱，並有短彎吹管。
- 板胡：Britannica 描述其為胡琴類兩弦拉弦樂器，木質音板、木或椰殼半圓共鳴體，弓穿過兩弦。
- 二胡：Met 描述胡琴的弓毛穿過弦間，二胡通常有圓形或六角形琴筒與蟒皮面。
- 高胡 / 中胡：Eason 與 Timbre and Orchestration 明確區分高胡較小較高、中胡較大較低；中胡有較厚弦與較大琴體。
- 革胡：Eason 描述革胡為 erhu 與 cello 混合的大型低音拉弦樂器，有 body、bridge、spine、bow 與動物皮覆蓋琴體。

## Gate

執行：

```bash
python3 fastlane/scripts/check_artwork_visual_review_cards.py
```

此 gate 只確認審核卡完整且來源、候選圖、規格、approval draft 對得上。嚴格送審仍會由 `check_artwork_review_scorecard.py --strict`、`check_artwork_morphology_specs.py --strict` 和 `import_approved_artwork.py` 要求真正的專業審核結果。
