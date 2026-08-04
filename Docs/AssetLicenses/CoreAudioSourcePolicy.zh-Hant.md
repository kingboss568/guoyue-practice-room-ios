# 核心音源來源政策

最後更新：2026-06-15

本 App 的付費價值建立在「專業演奏者聽得出是真實國樂器」這件事上。重新上架前，樂器圖鑑、聽辨與 Pro 練習路線使用的核心樂器聲音，一律只能使用可商用、可稽核、可重現處理流程的真實樂器錄音。

## Approved 門檻

每一筆可放入 App bundle 的 approved 音源必須同時具備：

- 真實樂器、人類演奏或可確認的實器錄音來源。
- 清楚授權，可商用，且授權連結可公開查核。
- 來源頁、作者、授權、原始檔、轉檔流程、SHA-256 都寫入 `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json`。
- App master WAV 為 mono 44.1 kHz 16-bit，且來源 WAV 與 bundle WAV hash 一致。
- 專業聽辨通過，尤其二胡、高胡、中胡、革胡、笙、嗩吶、板胡等高風險樂器。

## 禁用來源

下列來源不得作為 approved 核心音源，即使平台頁面顯示可商用或 CC0：

- Suno/Udio/generative music output。
- AI-generated instrument tone。
- VST or sample library playback。
- YouTube/CD/streaming extraction。
- unknown performer or unknown license。
- background music with unclear composition rights。
- environmental noise that obscures the instrument。

Suno 可用於內部編曲草稿或非核心氛圍測試，但不得包裝成真實國樂器音色，也不得放入付費聽辨核心素材。

## Candidate 與 Rejected

- `candidate`：可商用授權看似可行，但尚未完成授權揭露、原始檔取得、音質審聽或專業樂器辨識。
- `rejected`：來源已確認不符合政策，例如 VST、AI、樣本庫、不可商用、來源不明或音質無法專業使用。
- `candidate` 和 `rejected` 都不得被 `TonePlayer` 播放，也不得複製到正式訓練 bundle 作為可購買內容。

## 已知拒用案例

- `001-Erhu D4.wav`：Freesound 頁面雖標示 CC0，但描述寫明錄自 free VST instrument，不是真實二胡實器錄音；不可用於二胡核心音源。

## 送審前稽核

`fastlane/scripts/validate_submission_ready.sh` 會檢查：

- 本政策文件存在。
- 採購 tracker 的禁用來源清單包含 AI/Suno/VST/串流抽取等項目。
- approved manifest 不含被禁用來源字樣。
- rejected manifest 項目不會被列入 App 內候選來源或 approved 來源。
