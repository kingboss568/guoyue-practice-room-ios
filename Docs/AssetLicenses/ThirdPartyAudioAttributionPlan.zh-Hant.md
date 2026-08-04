# 第三方音源 attribution 與候選審聽規則

日期：2026-06-15

## 原則

`Design/Source/VerifiedAudio/candidates/` 內的檔案只供本地審聽，不是正式 App 內建素材。候選音源即使可商用，也不得在下列條件完成前移入 `GuoYueZhiPu/Resources/Audio/Instruments/`：

- 已確認授權允許商業 App 內散布與必要轉檔。
- App 內「音源來源與授權」頁已列出樂器、來源、作者、授權與來源連結。
- 若授權為 CC BY / CC BY-SA，需保留 attribution，且清楚標示改作處理，例如轉檔、正規化、淡入。
- CC BY-SA 候選必須先決定 ShareAlike 對轉檔 WAV 與 App 內散布的處理方式；未決定前只能作為候選，不可 approved。
- 高風險樂器如嗩吶、板胡、二胡、高胡、中胡、革胡必須通過專業國樂演奏者聽辨。

## 目前本地 audition 候選

| 樂器 | 來源 | 作者 | 授權 | 狀態 |
|---|---|---|---|---|
| 琵琶 | `Pipa - sound.ogg` | Francesc Fort | CC BY-SA 4.0 | 本地審聽候選，不包入 |
| 嗩吶 | `Suona.ogg` | Francesc Fort | CC BY-SA 4.0 | 本地審聽候選，不包入 |
| 中阮 | `Zhongruan.ogg` | Francesc Fort | CC BY-SA 4.0 | 本地審聽候選，不包入 |
| 板胡 | `Banhu.ogg` | Francesc Fort | CC BY-SA 4.0 | 本地審聽候選，不包入 |

## 升級 approved 前必查

1. 試聽是否為真實樂器，而非 VST、sample library 或 AI 生成。
2. 起音、共鳴、尾音、技法是否符合專業國樂使用者預期。
3. 背景噪音、混響、剪輯痕跡是否會誤導練習者。
4. 授權與 attribution 是否可在 App 內完整揭露。
5. `verified_audio_sources.json`、`AssetCredits.swift`、`VerifiedAudioSources.zh-Hant.md` 三處是否同步。

只有完成上述檢查，才能使用 `import_verified_audio.py` 或等價流程把音檔移入正式 approved manifest。
