# 開放音源搜尋與淘汰紀錄

日期：2026-08-04

本紀錄補在真實音檔採購流程之前，用來防止核心素材混入看似免費、但不適合專業國樂練習 App 的來源。公開來源只有在實器身分、原始頁、商用與改作條款、作者標示、檔案 hash、剪輯紀錄及格式檢查都通過時，才可成為正式音檔；其餘來源只能作候選或外部參考。

## 不可用於核心音檔

- Suno、Udio 或其他生成音樂 API 產物。
- AI-generated instrument tone。
- VST、sample library、GarageBand/iPad 合成音色。
- YouTube、CD、串流、教學影片或現場影片擷取。
- Pixabay 或 generic royalty-free 背景音樂，除非能追到明確的單件實器原始 stem、演奏者、授權與可商用再散布條款。
- 不明演奏者、不明授權、或環境聲遮蔽樂器本體的錄音。

這些來源可以拿來做內部參考，但不能包裝成專業演奏者會購買的訓練音色。

## 歷史候選處理結果

- Wikimedia Commons／Zenodo 中通過來源、授權、實器身分、hash 與格式檢查的 16 種實器音檔，已列入 `verified_audio_sources.json`。沒有取得的具名專業審聽紀錄不會被虛構；未來新增或高風險錄音仍須走真實審聽流程。
- 未通過授權或無法證明單件實器身分的歷史候選仍不得包入。
- Freesound `Lenguaverde` 的二胡街頭錄音：可能是真實二胡，但環境噪音與表演場景權利風險未清。
- Freesound `sazanami12` 的 Dagu/Chinese Bass Drum one-shot：無法單獨證明能代表本 App 的堂鼓條目，未採用。
- QMUL Beijing Opera percussion dataset 的 Daluo/Naobo：可做鑼、鈸候選，但 attribution、dataset citation、形制對應必須先確認。

## 目前外部示範／未內嵌項目

管子、箜篌、中胡、革胡、編鐘、堂鼓、排鼓目前沒有足夠乾淨且可直接商用再散布的公開單件實器音源。這 7 項只提供經稽核的原站實器示範連結，不複製、不熱連、不列入聽辨題；若要在 App 內播放，仍須走真人實器錄音委託包。高胡已於 2026-08-04 以 Wikimedia Commons 的《連環扣》高胡實奏、CC BY-SA 4.0 來源完成正式匯入。

## 2026-06-15 追加搜尋紀錄

本輪使用 Wikimedia Commons API 的 file namespace 搜尋下列關鍵字：`yangqin sound`、`xiao flute sound`、`sanxian sound`、`liuqin sound`、`guanzi sound`、`konghou sound`、`gaohu sound`、`zhonghu sound`、`gehu sound`、`bianzhong sound`、`muyu sound`、`paigu sound`。同時直接檢查 `File:Yangqin.ogg`、`File:Xiao.ogg`、`File:Sanxian.ogg`、`File:Liuqin.ogg`、`File:Guanzi.ogg`、`File:Konghou.ogg`、`File:Gaohu.ogg`、`File:Zhonghu.ogg`、`File:Gehu.ogg`、`File:Bianzhong.ogg`、`File:Muyu.ogg`、`File:Paigu.ogg`。

結果：沒有找到新的 clean、可商用再散布、可稽核、單件實器音檔。Commons API 對 `guanzi sound` 的唯一命中是 mixed ensemble MP3，不是管子單件音源；一般網路搜尋則多落在 YouTube、VST/sample-library、商品頁、Wikipedia 或教學介紹頁。

結論：這些缺口仍維持 `commission_required`。不得因公開來源不足而改用 YouTube 擷取、VST、generic royalty-free loop、mixed ensemble recording 或 AI/Suno 生成音。

## 2026-08-04 追加研究資料判定

- ChMusic 只涵蓋本 App 已有合法來源的樂器，且外部 530 MB 錄音資料未明確授權商用 App 再散布，因此只保留研究連結。
- CCMusic／CTIS 雖涵蓋更多樂器，但資料集標示 CC BY-NC-ND 4.0；NonCommercial 與 NoDerivatives 均不符合付費 App 的剪輯、轉檔及散布需求，完整資料另需申請授權，因此不下載、不剪輯、不包入。
- 本輪完成高胡的可核准單件實器來源；其餘 7 個缺口維持外部參考與 `commission_required`，不得加入 App 內試聽或聽辨題。

## 與送審 gate 的關係

`fastlane/scripts/check_open_audio_source_survey.py` 會確認：

- 調查檔覆蓋所有 `open_instrument_ids`。
- 每個缺音檔樂器都有 `candidate_needs_review` 或 `commission_required` 的明確結論。
- 需要委託錄音的項目仍在採購 tracker 中保持 `procure_real_recording`。
- 禁用來源清單包含 Suno/AI、VST/sample library、YouTube/CD/streaming extraction、Pixabay/generic royalty-free background music without verifiable instrument stem。
- 任何來源族群都不能被標成 approved；approved 只能由 `import_verified_audio.py` 匯入並寫入 verified audio manifest。

Commons 候選另由 `Design/Source/VerifiedAudio/procurement/candidate_license_review_pack.json` 與 `fastlane/scripts/check_candidate_audio_license_review.py` 管控。這些候選即使可商用，也仍維持 `blocked_pending_license_and_professional_review`，直到 attribution、ShareAlike、change notice、專業審聽與正式匯入流程全部完成。

這讓 App 在真實錄音尚未補齊前，維持誠實狀態：候選可以審查，但不會不小心變成可購買內容。
