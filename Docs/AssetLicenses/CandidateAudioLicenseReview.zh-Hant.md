# 候選音檔授權與專業審聽包

日期：2026-06-15

本文件只處理候選音檔，不代表 App 已補齊真實音檔。候選檔案目前只放在 `Design/Source/VerifiedAudio/candidates/`，不得複製到 `GuoYueZhiPu/Resources/Audio/Instruments/`。

## 本輪候選

已建立本地 audition WAV 與 hash 的 Commons 候選：

- 嗩吶 `suona`：[Suona.ogg](https://commons.wikimedia.org/wiki/File:Suona.ogg)
- 板胡 `banhu`：[Banhu.ogg](https://commons.wikimedia.org/wiki/File:Banhu.ogg)
- 琵琶 `pipa`：[Pipa - sound.ogg](https://commons.wikimedia.org/wiki/File:Pipa_-_sound.ogg)
- 中阮 `zhongruan`：[Zhongruan.ogg](https://commons.wikimedia.org/wiki/File:Zhongruan.ogg)

Wikimedia Commons 頁面顯示這些檔案為 Francesc Fort / TaronjaSatsuma 上傳的 own work，授權為 CC BY-SA 4.0。Creative Commons BY-SA 4.0 deed 說明：可分享、改作並可商用，但必須署名、提供授權連結、標示修改；若改作，改作部分需用同一或相容授權散布，且不得加上額外法律或技術限制。

## 上架前不得跳過的 gate

1. Attribution：App 內來源頁、Support/授權頁必須列出 title、author、source URL、license name、license URL、change notice。
2. ShareAlike：若 audition WAV 有轉檔、裁切、正規化、淡入淡出或重新 mastering，必須先決定改作音檔的散布方式與授權標示。
3. No additional restrictions：不可讓 App Store 包裝或 DRM 變成唯一可取得形式；若使用 CC BY-SA 改作音檔，要保留可履行授權的取得與說明方式。
4. Professional listening：嗩吶、板胡必須由對應聲部演奏者確認音色、起音、裝飾音、共鳴與樂器身分；琵琶與中阮也需確認不混淆。
5. Import path：只有 `import_verified_audio.py --approve` 可以把通過項目寫入 approved manifest 與 App bundle。

## 目前結論

這四個候選皆為 `blocked_pending_license_and_professional_review`。它們可以交給專業者審聽，也可以作為委託錄音時的比對參考；但在授權處理與審聽完成前，不能算入 22 件實器錄音完成數，也不能出現在 StoreKit paywall 或 App Store metadata 的完成承諾中。

## 驗證

執行：

```bash
python3 fastlane/scripts/check_candidate_audio_license_review.py
```

這個 gate 會確認：

- 每個 CC BY-SA audition candidate 都有 license review 條目。
- candidate 仍是 blocked 狀態，且不在 App bundle。
- 必填的 attribution、ShareAlike、change notice、professional listening 欄位都存在。
- 文件明確保留「不可包入 App」狀態。
