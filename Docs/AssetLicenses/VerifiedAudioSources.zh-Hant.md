# 真實音檔來源與授權紀錄

最後更新：2026-08-04

## 使用原則

這個 App 的目標使用者是國樂專業演奏者，音色錯誤會直接破壞信任。重新上架前，App bundle 內每一個 `GuoYueZhiPu/Resources/Audio/Instruments/<instrument_id>.wav` 都必須對應 `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json` 的 `approved` 條目。

不可把下列素材包進正式版：

- 未授權擷取的 YouTube、CD、串流平台或教學網站音檔。
- 只寫 royalty-free 但未允許 App 內再散布的素材。
- Suno 或其他生成音樂 API 產生、但不能證明是實器且不能通過專業聽辨的音色。
- VST、通用取樣器、電子合成器音色冒充國樂實器。

## 目前核准狀態

- 16 件可包入 App 的授權實器 WAV：笛、笙、鈸、簫、二胡、古箏、柳琴、琵琶、三弦、嗩吶、揚琴、中阮、板胡、高胡、鑼、木魚。
- 高胡新增來源為 Wikimedia Commons《連環扣》高胡獨奏，張沛堅演奏，CC BY-SA 4.0；App master SHA-256 為 `0f202689dddfe0163a871cb7dc0fb66a8cee37d216a5891be45183ce43fea32e`。
- 管子、箜篌、中胡、革胡、編鐘、堂鼓、排鼓只有原站真人示範連結，全部標記 `bundled=false`、`quiz_eligible=false`，不複製影音、不進入聽辨題。
- 完整逐件來源、作者、授權、URL、雜湊、格式與外部參考，以 `Design/Source/VerifiedAudio/manifests/verified_audio_sources.json` 為唯一權威清單。

## 2026-06-15 早期來源調查紀錄（保留稽核歷史）

下列候選與「待補」描述是早期調查快照，不代表目前 App 狀態；凡與上方摘要不同，均以目前 manifest 為準。

### 當時已核准可包入 App

### 笛 `dizi`

- 來源：[Wikimedia Commons - DiZi Chinese Flute Sample.ogg](https://commons.wikimedia.org/wiki/File:DiZi_Chinese_Flute_Sample.ogg)
- 原始來源：Freesound `Gorgoroth6669/sounds/108242`
- 作者：Gorgoroth6669
- 日期：2010-11-08
- 授權：CC0 1.0 Universal Public Domain Dedication
- Wikimedia 授權檢查：2016-01-10 已確認原始 Freesound 授權
- App 內檔案：`GuoYueZhiPu/Resources/Audio/Instruments/dizi.wav`
- SHA-256：`05b176c70beb925e6b67b834a8afce3e48507181095a5c64651755fc8a2680bf`
- 處理：原始 Ogg 轉成 mono、44.1 kHz、16-bit WAV，做音量正規化與短淡入淡出

### 笙 `sheng`

- 來源：[Wikimedia Commons - Soprano Sheng Chromatic Scale.ogg](https://commons.wikimedia.org/wiki/File:Soprano_Sheng_Chromatic_Scale.ogg)
- 作者：S099001
- 日期：2017-11-12
- 授權：CC0 1.0 Universal Public Domain Dedication
- Wikimedia 頁面說明：三十六簧高音笙吹奏半音階，作者自作並以 CC0 釋出
- App 內檔案：`GuoYueZhiPu/Resources/Audio/Instruments/sheng.wav`
- SHA-256：`f7ae3d73410603c79988b270a42ca76ac60956a51287b4434a6c088b700cf958`
- 處理：原始 Ogg 轉成 mono、44.1 kHz、16-bit WAV，做音量正規化與短淡入淡出

### 當時候選但尚未包入 App

### 琵琶 `pipa`

- 來源：[Wikimedia Commons - Pipa - sound.ogg](https://commons.wikimedia.org/wiki/File:Pipa_-_sound.ogg)
- 作者：Francesc Fort
- 授權：CC BY-SA 4.0
- 狀態：候選，不包入
- 原因：需要先處理 attribution、share-alike 及 App 內散布策略，且需確認錄音內容是否適合作為單件樂器示範。

### 嗩吶 `suona`

- 來源：[Wikimedia Commons - Suona.ogg](https://commons.wikimedia.org/wiki/File:Suona.ogg)
- 作者：Francesc Fort
- 授權：CC BY-SA 4.0
- 狀態：候選，不包入
- 原因：需要先處理 attribution、share-alike 及 App 內散布策略；嗩吶又是專業者最容易聽出錯誤的高風險音色，需真人審聽後才可考慮。

### 中阮 `zhongruan`

- 來源：[Wikimedia Commons - Zhongruan.ogg](https://commons.wikimedia.org/wiki/File:Zhongruan.ogg)
- 作者：Francesc Fort
- 授權：CC BY-SA 4.0
- 狀態：候選，不包入
- 原因：需要先處理 attribution、share-alike 及 App 內散布策略，且需確認內容足以代表中阮音色。

### 板胡 `banhu`

- 來源：[Wikimedia Commons - Banhu.ogg](https://commons.wikimedia.org/wiki/File:Banhu.ogg)
- 作者：Francesc Fort
- 授權：CC BY-SA 4.0
- 狀態：候選，不包入
- 原因：需要先處理 attribution、share-alike 及 App 內散布策略；板胡屬高風險胡琴類，必須通過專業聽辨後才可使用。

### 二胡 `erhu`

- 來源：[Freesound - 001-Erhu D4.wav](https://freesound.org/people/tarane468/sounds/467479/)
- 作者：tarane468
- 授權：CC0
- 狀態：退回，不包入
- 原因：頁面說明此音檔來自 free VST instrument，不是真實二胡演奏錄音。即使授權可用，也不符合本 App 的專業可信度門檻。

### 古箏 `guzheng`

- 來源：[Freesound - GUZHENG - instrument- Single Note - Sound](https://freesound.org/people/nanliu_music/sounds/847157/)
- 作者：nanliu_music
- 授權：CC0
- 狀態：候選，不包入
- 原因：頁面說明為乾淨的傳統古箏錄音，但原始 WAV 需登入下載並試聽確認，尚未完成品質檢查與本地授權留存。

### 二胡 `erhu`

- 來源：[Freesound - Chinese Violin - The Enchanted Sound of the Erhu](https://freesound.org/people/Lenguaverde/sounds/423496/)
- 作者：Lenguaverde
- 授權：CC0
- 狀態：候選，不包入
- 原因：較可能是真實街頭二胡錄音，但含交通/環境聲與街頭表演情境；若作為專業練習音色，需先通過品質與權利風險審核。

### 堂鼓 `tanggu`

- 來源：[Freesound - Chinese Bass Drum Dagu - Center Stroke on Drumhead - Loud](https://freesound.org/people/sazanami12/sounds/856549/)
- 作者：sazanami12
- 授權：CC0
- 狀態：候選，不包入
- 原因：頁面標示為台北錄製的 Huapengu / Dagu / Chinese Bass Drum 單擊，授權條件乾淨；但它是短 one-shot，且需確認與 App 的「堂鼓」條目是否足夠匹配，還需補 rim/roll 或其他 take。

### 鑼 `luo`

- 來源：[Freesound - daluo_50](https://freesound.org/people/ajaysm/sounds/222237/)
- 作者：ajaysm / QMUL BeijingOperaPercussion dataset
- 授權：CC BY 4.0
- 狀態：候選，不包入
- 原因：頁面說明為京劇打擊樂 Daluo 單擊，錄音者/演奏者/錄音地點清楚；但需處理 attribution、論文/資料集引用要求，並確認 Daluo 是否適合替代 App 內泛稱「鑼」。

### 鈸 `bo`

- 來源：[Freesound - naobo_38](https://freesound.org/people/ajaysm/sounds/222274/)
- 作者：ajaysm / QMUL BeijingOperaPercussion dataset
- 授權：CC BY 4.0
- 狀態：候選，不包入
- 原因：頁面說明為京劇打擊樂 Danao / Naobo cymbals 單擊；需處理 attribution、確認形制是否符合 App 的「鈸」，並補 crash/choke/soft touch 多種 take。

### 其他已查但不建議直接包入

- [Freesound - Drums of Xian, China](https://freesound.org/people/RTB45/sounds/234922/)：含 tanggu、paigu、muyu 等標籤，但屬於西安城牆鼓樂現場表演，聲源混合且有場地情境，不適合作為單一樂器音色樣本。

### 當時公開來源查找結論

公開 CC0 / CC BY 音源對打擊樂較容易找到候選；笙已找到可稽核的 CC0 實器錄音並替換進 App。二胡、高胡、中胡、革胡、嗩吶、板胡仍是高風險音色，應維持委託真人演奏者錄製的策略；公開來源只能作為臨時候選或比對參考。

### 當時待補 21 件

嗩吶、簫、管子、琵琶、古箏、揚琴、柳琴、中阮、三弦、箜篌、二胡、高胡、中胡、板胡、革胡、編鐘、堂鼓、鑼、鈸、木魚、排鼓。

這 21 件目前仍不得宣稱為真實可驗證音檔。若要快速補齊，優先方向是向國樂演奏者採購短句或單音錄音，簽一份明確允許商業 App 內散布與剪輯轉檔的授權。

收到錄音後，必須透過 `fastlane/scripts/import_verified_audio.py` 匯入；不得手工覆蓋 bundle WAV 後直接送審。
