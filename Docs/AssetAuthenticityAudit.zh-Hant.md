# 國樂團練習室素材可信度稽核

更新日期：2026-08-04

## 結論

新版已停止用電子波形、VST、AI 音色或相近樂器冒充國樂器，也不會因為檔案「可下載」就推定可在商業 App 再散布。

目前完成狀態：

- 23 種樂器中，16 種已有可稽核、允許商用再散布的實器 WAV；其餘 7 種只開啟可追溯的原站真人示範，不複製影音、不進入付費聽辨題。
- 23 種樂器中，22 種已有逐檔授權的真實照片；排鼓仍顯示中性待補卡，不顯示舊版想像圖。
- 舊版 8 個相同長度的產生式 WAV 與排鼓想像圖已從 App bundle 移除；高胡已改用 Wikimedia Commons 的真人獨奏實錄，其餘 7 個舊 WAV 維持移除。
- 所有合法來源、作者、授權、轉檔後 SHA-256 與 App 內揭露，分別登錄於 `Design/Source/VerifiedAudio`、`Design/Source/VerifiedPhotos` 與 `Models/AssetCredits.swift`。

素材策略已完成可稽核覆蓋，但送審仍須完成 IAP 實機證據、全新商店截圖、Git push、精確 Xcode Cloud `VALID` build 與 App Store Connect 即時狀態驗證。排鼓在取得可商用完整實拍前，維持待補卡與官方實器來源連結，不以錯誤圖片補位。

## 已核准實器音檔（16 / 23）

- 笛、笙：Wikimedia Commons，CC0。
- 鈸、簫、二胡、古箏、柳琴、琵琶、三弦、嗩吶、揚琴、中阮：Zenodo DOI `10.5281/zenodo.8012071`，CC BY 4.0。
- 板胡：Wikimedia Commons，CC BY-SA 4.0。
- 高胡：Wikimedia Commons《連環扣》高胡獨奏，張沛堅演奏，CC BY-SA 4.0，來源頁含 VRT 授權紀錄。
- 鑼：Wikimedia Commons，CC0。
- 木魚：Freesound，CC BY 4.0。

所有 App master 都是 44.1 kHz、16-bit、mono WAV。完整檔名、來源網址、作者、授權、秒數與雜湊以 `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json` 為準。

## 原站真人示範（7 / 23，未包入 App）

- 管子 `guanzi`
- 箜篌 `konghou`
- 中胡 `zhonghu`
- 革胡 `gehu`
- 編鐘 `bianzhong`
- 堂鼓 `tanggu`
- 排鼓 `paigu`

這些樂器目前沒有可合法包入商業 App、又足以作隔離聽辨的錄音。樂器頁只連到香港康樂及文化事務署音樂事務處、CCTV、湖北省博物館或可稽核的實錄來源頁；App 不下載、不熱連、不擷取，也不列入付費聽辨題。中胡、革胡不可拿二胡或大提琴代替；堂鼓與排鼓不可拿通用 bass drum 代替；編鐘不可拿合成鐘聲代替。

維持從 bundle 移除的舊檔：`guanzi.wav`、`konghou.wav`、`zhonghu.wav`、`gehu.wav`、`bianzhong.wav`、`tanggu.wav`、`paigu.wav`。`gaohu.wav` 已用上述授權實錄重新製作，不沿用舊版音色。

## ChMusic 研究資料判定

2026-08-04 查核 arXiv `2108.08470` 與作者 GitHub：

- 論文列出 11 種樂器與 55 段單樂器錄音，但全部是本 App 已有核准來源的樂器，沒有補到上述 7 種外部參考項目。
- GitHub 的 MIT LICENSE 可確認涵蓋 repository 內的程式與文件；530 MB 音檔是外部 Google Drive／Baidu 連結，README 與論文沒有清楚授予錄音及曲目在商業 App 內再散布的權利。
- 因此 ChMusic 只列為研究連結，不匯入 App。詳細判定在 `Design/Source/VerifiedAudio/procurement/rejected_research_sources.json`。

## 圖片狀態（22 / 23）

22 張圖片均來自 Wikimedia Commons、The Met Open Access 或 Openverse 導向的 Flickr 原始頁，逐檔保存來源、作者、授權與衍生檔雜湊。革胡使用 `Antique Gehu Chinese bass` 實拍，CC BY 2.0。

排鼓仍缺少可商用再利用且能清楚辨識完整排鼓形制的實拍，因此已移除舊版想像圖，App 顯示「實拍授權待補」。不得用商店商品圖、新聞照或沒有再利用條款的官方演出照補位。

## 不得使用的音源

- 未授權 YouTube、Spotify、CD 或網站音檔擷取。
- 僅標示 royalty-free、但禁止 App redistribution 的素材。
- AI／Suno 生成、VST、sample library 或通用 synth preset。
- 混合樂團、環境噪音或無法確認是哪一件樂器的錄音。
- 曲目著作權、錄音著作權或演奏者同意任一項不明的素材。

## 程式防線

- `TonePlayer` 只對 `AudioSourceCatalog.approvedSources` 播放 bundle 內 WAV；其餘樂器由 `ExternalInstrumentDemonstrationCatalog` 開啟原站，不會 fallback。
- `InstrumentArtwork` 只對 `PhotoSourceCatalog.verifiedSources` 顯示照片；未核准樂器顯示待補卡。
- `Tools/generate_media_assets.py` 不再產生合成音檔。
- `fastlane/scripts/check_asset_authenticity.py --strict` 驗證來源狀態、檔案存在、bundle 一致、SHA-256 與 WAV 格式。

## 送審門檻

重新送審前必須全部完成：

- 16 件內建音檔的實器身分、商用授權、來源、作者、雜湊與格式均吻合；7 件外部示範必須維持 `bundled=false`、`quiz_eligible=false` 且連結可開。
- 22 件內建照片的真實樂器身分、商用授權、來源、作者與雜湊均吻合；排鼓保持不誤導的待補卡與官方實器來源連結。
- IAP 產品、購買與恢復的實機／Sandbox 證據。
- iPhone 6.9 吋與 iPad 13 吋各 6 張新版截圖，包含付款頁。
- Support／Privacy 正式網址可開、文件在 Git repo 且已 push。
- `fastlane ios validate_submission` 全部通過。
- Xcode Cloud `Archive - iOS` 產生的精確 build 在 App Store Connect 成為 `VALID`；Fastlane 只選取該 build、上傳 metadata／截圖並送審，不在本機產生 binary。
