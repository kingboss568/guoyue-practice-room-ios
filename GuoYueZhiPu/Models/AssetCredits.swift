import Foundation

enum AudioSourceStatus: String {
    case approved
    case candidate
    case pending

    var title: String {
        switch self {
        case .approved:
            return "已核准實器音檔"
        case .candidate:
            return "候選來源待審"
        case .pending:
            return "待補實器錄音"
        }
    }
}

struct AudioSourceCredit: Identifiable, Hashable {
    let instrumentID: String
    let instrumentName: String
    let sourceTitle: String
    let sourceURL: URL?
    let author: String
    let license: String
    let status: AudioSourceStatus
    let note: String
    let sha256: String?

    var id: String { instrumentID }

    var isPlayable: Bool {
        status == .approved
    }
}

enum AudioSourceCatalog {
    private static func zenodoSource(
        instrumentID: String,
        instrumentName: String,
        datasetLabel: String,
        sourceFile: String,
        sha256: String
    ) -> AudioSourceCredit {
        AudioSourceCredit(
            instrumentID: instrumentID,
            instrumentName: instrumentName,
            sourceTitle: "China traditional music instrument dataset — \(datasetLabel) / \(sourceFile)",
            sourceURL: URL(string: "https://zenodo.org/records/8012071"),
            author: "Zhen Li、Hao Zhou、Shusong Xing、Binhui Wang",
            license: "CC BY 4.0",
            status: .approved,
            note: "Zenodo DOI 10.5281/zenodo.8012071；資料集明確標示為該樂器的三秒實器獨奏，已核對來源、商用授權、檔案雜湊與格式，並轉為單聲道 44.1 kHz / 16-bit WAV。",
            sha256: sha256
        )
    }

    static let approvedSources: [AudioSourceCredit] = [
        AudioSourceCredit(
            instrumentID: "dizi",
            instrumentName: "笛",
            sourceTitle: "DiZi Chinese Flute Sample.ogg",
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:DiZi_Chinese_Flute_Sample.ogg"),
            author: "Gorgoroth6669",
            license: "CC0 1.0 Universal Public Domain Dedication",
            status: .approved,
            note: "Wikimedia Commons / Freesound 來源，已轉為 App master WAV。",
            sha256: "05b176c70beb925e6b67b834a8afce3e48507181095a5c64651755fc8a2680bf"
        ),
        AudioSourceCredit(
            instrumentID: "sheng",
            instrumentName: "笙",
            sourceTitle: "Soprano Sheng Chromatic Scale.ogg",
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Soprano_Sheng_Chromatic_Scale.ogg"),
            author: "S099001",
            license: "CC0 1.0 Universal Public Domain Dedication",
            status: .approved,
            note: "三十六簧高音笙半音階，已轉為 App master WAV。",
            sha256: "f7ae3d73410603c79988b270a42ca76ac60956a51287b4434a6c088b700cf958"
        ),
        zenodoSource(
            instrumentID: "bo",
            instrumentName: "鈸",
            datasetLabel: "Ba",
            sourceFile: "audio_535.mp3",
            sha256: "8235fb8d850259bc9549197fb0d8ec2a176fc26bfab254e330be9d02165f33ca"
        ),
        zenodoSource(
            instrumentID: "xiao",
            instrumentName: "簫",
            datasetLabel: "Dongxiao",
            sourceFile: "audio_999.mp3",
            sha256: "19e8067f34dbf8ac7b599073917d7266b6dd5df721875859afe7cdb78e9c8f62"
        ),
        zenodoSource(
            instrumentID: "erhu",
            instrumentName: "二胡",
            datasetLabel: "Erhu",
            sourceFile: "audio_142.mp3",
            sha256: "a2cc3398c8901dd4f776a121e92b8eb697c3672925dd08e5860e1eecdf1ecfbd"
        ),
        zenodoSource(
            instrumentID: "guzheng",
            instrumentName: "古箏",
            datasetLabel: "Guzheng",
            sourceFile: "audio_1.mp3",
            sha256: "1dcdc18d1ddd3a40444aaa5ddfbd69f5724e26545be9abbb6fff73a359d5f1fc"
        ),
        zenodoSource(
            instrumentID: "liuqin",
            instrumentName: "柳琴",
            datasetLabel: "Liuqin",
            sourceFile: "audio_99.mp3",
            sha256: "21abfb1483af6a0b68ddf0cb114e0c54363250f9d9cc61b03b3955605dedf472"
        ),
        zenodoSource(
            instrumentID: "pipa",
            instrumentName: "琵琶",
            datasetLabel: "Pipa",
            sourceFile: "audio_1314.mp3",
            sha256: "915acbf9fa36ceccb0cc0a3556e153bc06b70222c5729090fe2d11ce0f5eb2f9"
        ),
        zenodoSource(
            instrumentID: "sanxian",
            instrumentName: "三弦",
            datasetLabel: "Sanxian",
            sourceFile: "audio_1.mp3",
            sha256: "b9c29e2ffbee42f085f3e9d4afeaf36f572024c267a54c0d171c2d7ea15e68f5"
        ),
        zenodoSource(
            instrumentID: "suona",
            instrumentName: "嗩吶",
            datasetLabel: "Suona",
            sourceFile: "audio_208.mp3",
            sha256: "db6e01caf808dcd7ef711d13b5e89841142858f3cb64355afd870e7df7e73c37"
        ),
        zenodoSource(
            instrumentID: "yangqin",
            instrumentName: "揚琴",
            datasetLabel: "Yangqin",
            sourceFile: "audio_497.mp3",
            sha256: "b0f3934aaf52211e5c99e7b97be7ed4b7b180b6f3c37cdb7539797f36934889b"
        ),
        zenodoSource(
            instrumentID: "zhongruan",
            instrumentName: "中阮",
            datasetLabel: "Zhongruan",
            sourceFile: "audio_1.mp3",
            sha256: "3e7ed39eb6f0430de4fe0ada8a5e6b3b76005fe9b18cdbf5ef43fce5759ff78d"
        ),
        AudioSourceCredit(
            instrumentID: "banhu",
            instrumentName: "板胡",
            sourceTitle: "Banhu.ogg",
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:Banhu.ogg"),
            author: "Francesc Fort",
            license: "CC BY-SA 4.0",
            status: .approved,
            note: "Wikimedia Commons 實器板胡錄音；核對來源與商用授權後，截取三秒並轉為單聲道 44.1 kHz / 16-bit WAV。",
            sha256: "37730a581d8adac3d564027fb7750b57e33dc3ecc413d511049b19427b05e57d"
        ),
        AudioSourceCredit(
            instrumentID: "gaohu",
            instrumentName: "高胡",
            sourceTitle: "連環扣（高胡獨奏）",
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:%E8%BF%9E%E7%8E%AF%E6%89%A3.ogg"),
            author: "張沛堅 (Zhang Peijian)",
            license: "CC BY-SA 4.0",
            status: .approved,
            note: "Wikimedia Commons 上由張沛堅演奏的高胡獨奏實錄，來源頁含 VRT 授權紀錄；截取五秒並轉為單聲道 44.1 kHz / 16-bit WAV。",
            sha256: "0f202689dddfe0163a871cb7dc0fb66a8cee37d216a5891be45183ce43fea32e"
        ),
        AudioSourceCredit(
            instrumentID: "luo",
            instrumentName: "鑼",
            sourceTitle: "Chinese Gong finish session",
            sourceURL: URL(string: "https://commons.wikimedia.org/wiki/File:240382_the-very-real-horst_chinese-gong-finish-session-2014-06-10-29-143.wav"),
            author: "the_very_Real_Horst",
            license: "CC0 1.0",
            status: .approved,
            note: "大型中國鑼實器錄音；截取擊奏與衰減並轉為單聲道 44.1 kHz / 16-bit WAV。",
            sha256: "809f2b3326b889f535bd10790173cb05bd86beab8a1274ef7c09c42388e7b190"
        ),
        AudioSourceCredit(
            instrumentID: "muyu",
            instrumentName: "木魚",
            sourceTitle: "Fischtrommel_Muyu.mp3",
            sourceURL: URL(string: "https://freesound.org/people/the_very_Real_Horst/sounds/205999/"),
            author: "the_very_Real_Horst",
            license: "CC BY 4.0",
            status: .approved,
            note: "中國木魚實器錄音的 Freesound 高品質預覽；截取五秒並轉為單聲道 44.1 kHz / 16-bit WAV。",
            sha256: "e5998c4e50bdb043209b10ae5d6cb901711d765a5cab1e04d01eef781ac18206"
        )
    ]

    static let candidateSources: [AudioSourceCredit] = []

    static let approvedIDs: Set<String> = Set(approvedSources.map(\.instrumentID))

    static func source(for instrumentID: String) -> AudioSourceCredit? {
        approvedSources.first { $0.instrumentID == instrumentID }
            ?? candidateSources.first { $0.instrumentID == instrumentID }
    }

    static func approvedSource(for instrumentID: String) -> AudioSourceCredit? {
        approvedSources.first { $0.instrumentID == instrumentID }
    }

    static func source(for instrument: Instrument) -> AudioSourceCredit? {
        source(for: instrument.id)
    }

    static func approvedSource(for instrument: Instrument) -> AudioSourceCredit? {
        approvedSource(for: instrument.id)
    }
}

struct ExternalInstrumentDemonstration: Identifiable, Hashable {
    let instrumentID: String
    let instrumentName: String
    let sourceTitle: String
    let sourceURL: URL
    let provider: String
    let note: String

    var id: String { instrumentID }
}

enum ExternalInstrumentDemonstrationCatalog {
    private static let lcsdGuideURL = URL(
        string: "https://www.lcsd.gov.hk/en/mo/musicguide/en/chinese_musical.html"
    )!

    static let references: [ExternalInstrumentDemonstration] = [
        ExternalInstrumentDemonstration(
            instrumentID: "guanzi",
            instrumentName: "管子",
            sourceTitle: "Chinese Musical Instruments — Guan",
            sourceURL: lcsdGuideURL,
            provider: "香港康樂及文化事務署音樂事務處",
            note: "原站提供管的實器聲音選段與演奏影片；只開啟來源頁，不複製、不串流嵌入，也不列入付費聽辨題。"
        ),
        ExternalInstrumentDemonstration(
            instrumentID: "konghou",
            instrumentName: "箜篌",
            sourceTitle: "《游子吟》箜篌演奏",
            sourceURL: URL(string: "https://tv.cctv.com/2019/02/27/VIDEbVvKYvHTGwaMdeWnNWfQ190227.shtml")!,
            provider: "中央廣播電視總台 CCTV",
            note: "CCTV 節目頁的真人箜篌演奏；只連到原站觀看，不擷取影音，也不列入付費聽辨題。"
        ),
        ExternalInstrumentDemonstration(
            instrumentID: "zhonghu",
            instrumentName: "中胡",
            sourceTitle: "Chinese Musical Instruments — Zhonghu",
            sourceURL: lcsdGuideURL,
            provider: "香港康樂及文化事務署音樂事務處",
            note: "原站提供中胡實器聲音選段與演奏影片；未取得再散布授權，因此 App 只開啟來源頁。"
        ),
        ExternalInstrumentDemonstration(
            instrumentID: "gehu",
            instrumentName: "革胡",
            sourceTitle: "Chinese Musical Instruments — Gehu",
            sourceURL: lcsdGuideURL,
            provider: "香港康樂及文化事務署音樂事務處",
            note: "原站提供革胡實器聲音選段與演奏影片；未取得再散布授權，因此 App 只開啟來源頁。"
        ),
        ExternalInstrumentDemonstration(
            instrumentID: "bianzhong",
            instrumentName: "編鐘",
            sourceTitle: "湖北省博物館編鐘樂團官方介紹",
            sourceURL: URL(string: "https://m-www.hbkgy.com/bzyt/p/9068.html")!,
            provider: "湖北省博物館",
            note: "官方介紹曾侯乙編鐘複製件與常態真人演奏；App 不採用音源商的合成或取樣音色。"
        ),
        ExternalInstrumentDemonstration(
            instrumentID: "tanggu",
            instrumentName: "堂鼓",
            sourceTitle: "Chinese Drum Performance in Xi'an",
            sourceURL: URL(string: "https://freesound.org/people/RTB45/sounds/234922/")!,
            provider: "RTB45 / Freesound",
            note: "西安現場真人鼓樂實錄，頁面標示 CC BY 4.0；因同時含堂鼓與排鼓編制、不是隔離單音，僅供原站參考，不包入 App 或題庫。"
        ),
        ExternalInstrumentDemonstration(
            instrumentID: "paigu",
            instrumentName: "排鼓",
            sourceTitle: "Chinese Musical Instruments — Paigu",
            sourceURL: lcsdGuideURL,
            provider: "香港康樂及文化事務署音樂事務處",
            note: "原站提供五件式排鼓的真實圖片、聲音與演奏影片；只開啟來源頁，不複製素材。"
        )
    ]

    static func reference(for instrumentID: String) -> ExternalInstrumentDemonstration? {
        references.first { $0.instrumentID == instrumentID }
    }

    static func reference(for instrument: Instrument) -> ExternalInstrumentDemonstration? {
        reference(for: instrument.id)
    }
}

struct PhotoSourceCredit: Identifiable, Hashable {
    let instrumentID: String
    let instrumentName: String
    let sourceTitle: String
    let sourceURL: URL?
    let author: String
    let license: String
    let licenseURL: URL?

    var id: String { instrumentID }
}

enum PhotoSourceCatalog {
    private static func commons(
        _ instrumentID: String,
        _ instrumentName: String,
        _ sourceTitle: String,
        _ author: String,
        _ license: String,
        _ sourceURL: String,
        _ licenseURL: String? = nil
    ) -> PhotoSourceCredit {
        PhotoSourceCredit(
            instrumentID: instrumentID,
            instrumentName: instrumentName,
            sourceTitle: sourceTitle,
            sourceURL: URL(string: sourceURL),
            author: author,
            license: license,
            licenseURL: licenseURL.flatMap(URL.init(string:))
        )
    }

    static let verifiedSources: [PhotoSourceCredit] = [
        commons("dizi", "笛", "Dizi (笛子) MET 89.4.61 slide.jpg", "The Metropolitan Museum of Art Open Access", "CC0", "https://commons.wikimedia.org/wiki/File:Dizi_(%E7%AC%9B%E5%AD%90_)_MET_89.4.61_slide.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("sheng", "笙", "Sheng MET DP216617.jpg", "The Metropolitan Museum of Art Open Access", "CC0", "https://commons.wikimedia.org/wiki/File:Sheng_MET_DP216617.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("suona", "嗩吶", "Musical instruments in the Yunnan Nationalities Museum - DSC03842.JPG", "Daderot", "Public domain", "https://commons.wikimedia.org/wiki/File:Musical_instruments_in_the_Yunnan_Nationalities_Museum_-_DSC03842.JPG"),
        commons("xiao", "簫", "Xiao MET DP216557.jpg", "The Metropolitan Museum of Art Open Access", "CC0", "https://commons.wikimedia.org/wiki/File:Xiao_MET_DP216557.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("guanzi", "管子", "Guanzi.jpg", "Wikimedia Commons contributor", "CC BY-SA 3.0", "https://commons.wikimedia.org/wiki/File:Guanzi.jpg", "https://creativecommons.org/licenses/by-sa/3.0/"),
        commons("pipa", "琵琶", "Pipa MET DP216711.jpg", "The Metropolitan Museum of Art Open Access", "CC0", "https://commons.wikimedia.org/wiki/File:Pipa_MET_DP216711.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("guzheng", "古箏", "2008 Summer Olympics Musical Instrument - Guzheng.jpg", "Gary Todd", "CC0", "https://commons.wikimedia.org/wiki/File:2008_Summer_Olympics_Musical_Instrument-_Guzheng.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("yangqin", "揚琴", "Yangqin, MIM PHX.jpg", "jowcol61", "CC BY 2.0", "https://commons.wikimedia.org/wiki/File:Yangqin,_MIM_PHX.jpg", "https://creativecommons.org/licenses/by/2.0/"),
        commons("liuqin", "柳琴", "Liuqin.jpg", "Sun Tzu2", "Public domain", "https://commons.wikimedia.org/wiki/File:Liuqin.jpg"),
        commons("zhongruan", "中阮", "Zhongruan.jpg", "Nariz", "CC BY-SA 3.0", "https://commons.wikimedia.org/wiki/File:Zhongruan.jpg", "https://creativecommons.org/licenses/by-sa/3.0/"),
        commons("sanxian", "三弦", "Phoenix Musical Instrument Museum - Sanxian.jpg", "Marine 69-71", "CC BY-SA 4.0", "https://commons.wikimedia.org/wiki/File:Phoenix-Musical_Instrument_Museum-Sanxian-China.jpg", "https://creativecommons.org/licenses/by-sa/4.0/"),
        commons("konghou", "箜篌", "Vertical Konghou (10096201556).jpg", "Gary Todd", "CC0", "https://commons.wikimedia.org/wiki/File:Vertical_Konghou_(10096201556).jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("erhu", "二胡", "Erhu in the Mets.jpg", "Unknown creator / The Met Open Access", "CC0", "https://commons.wikimedia.org/wiki/File:Erhu_in_the_Mets.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("gaohu", "高胡", "Gaohu 1.jpg", "LDHan", "Public domain", "https://commons.wikimedia.org/wiki/File:Gaohu_1.jpg"),
        commons("zhonghu", "中胡", "中胡.jpg", "三猎", "CC BY-SA 4.0", "https://commons.wikimedia.org/wiki/File:%E4%B8%AD%E8%83%A1.jpg", "https://creativecommons.org/licenses/by-sa/4.0/"),
        commons("banhu", "板胡", "Banhu, Tengwangge (30730619533).jpg", "Gary Todd", "CC0", "https://commons.wikimedia.org/wiki/File:Banhu,_Tengwangge_(Prince_of_Teng_Pavilion)_(30730619533).jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("gehu", "革胡", "Antique Gehu Chinese bass", "quinet", "CC BY 2.0", "https://www.flickr.com/photos/quinet/29924626624/", "https://creativecommons.org/licenses/by/2.0/"),
        commons("bianzhong", "編鐘", "Bianzhong.jpg", "Zzjgbc", "CC BY-SA 3.0", "https://commons.wikimedia.org/wiki/File:Bianzhong.jpg", "https://creativecommons.org/licenses/by-sa/3.0/"),
        commons("tanggu", "堂鼓", "Tánggǔ (堂鼓) MET DP219344.jpg", "Elevated Tone Workshop / The Met Open Access", "CC0", "https://commons.wikimedia.org/wiki/File:T%C3%A1ngg%C7%94_(%E5%A0%82%E9%BC%93)_MET_DP219344.jpg", "https://creativecommons.org/publicdomain/zero/1.0/"),
        commons("luo", "鑼", "Chinese gongs (34474311844).jpg", "Thomas Quine", "CC BY 2.0", "https://commons.wikimedia.org/wiki/File:Chinese_gongs_(34474311844).jpg", "https://creativecommons.org/licenses/by/2.0/"),
        commons("bo", "鈸", "Aachinaclash.jpg", "Wikimedia Commons contributor", "CC BY-SA 3.0", "https://commons.wikimedia.org/wiki/File:Aachinaclash.jpg", "https://creativecommons.org/licenses/by-sa/3.0/"),
        commons("muyu", "木魚", "Chinese Muyu QM r.jpg", "Queensland Museum", "CC BY-SA 3.0", "https://commons.wikimedia.org/wiki/File:Chinese_Muyu_QM_r.jpg", "https://creativecommons.org/licenses/by-sa/3.0/")
    ]

    static let blockedInstrumentIDs: Set<String> = ["paigu"]

    static func source(for instrumentID: String) -> PhotoSourceCredit? {
        verifiedSources.first { $0.instrumentID == instrumentID }
    }

    static func source(for instrument: Instrument) -> PhotoSourceCredit? {
        source(for: instrument.id)
    }
}
