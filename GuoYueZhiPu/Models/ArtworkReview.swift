import Foundation

enum ArtworkReviewStatus: String {
    case approvedAfterReview
    case approvedAfterProfessionalReview
    case needsRegeneration
    case needsDifferentiation
    case referenceCheckRequired

    var title: String {
        switch self {
        case .approvedAfterReview, .approvedAfterProfessionalReview:
            return "實拍來源已核對"
        case .needsRegeneration:
            return "待取得授權實拍"
        case .needsDifferentiation:
            return "形制差異待校正"
        case .referenceCheckRequired:
            return "圖片待參照校對"
        }
    }

    var isApproved: Bool {
        self == .approvedAfterReview || self == .approvedAfterProfessionalReview
    }
}

struct ArtworkReviewRecord: Identifiable, Hashable {
    let instrumentID: String
    let instrumentName: String
    let status: ArtworkReviewStatus
    let risk: String
    let requiredChecks: [String]

    var id: String { instrumentID }
}

enum ArtworkReviewCatalog {
    private static let verifiedPhotos: [(id: String, name: String)] = [
        ("dizi", "笛"), ("sheng", "笙"), ("suona", "嗩吶"), ("xiao", "簫"),
        ("guanzi", "管子"), ("pipa", "琵琶"), ("guzheng", "古箏"),
        ("yangqin", "揚琴"), ("liuqin", "柳琴"), ("zhongruan", "中阮"),
        ("sanxian", "三弦"), ("konghou", "箜篌"), ("erhu", "二胡"),
        ("gaohu", "高胡"), ("zhonghu", "中胡"), ("banhu", "板胡"),
        ("gehu", "革胡"),
        ("bianzhong", "編鐘"), ("tanggu", "堂鼓"), ("luo", "鑼"),
        ("bo", "鈸"), ("muyu", "木魚")
    ]

    static let records: [ArtworkReviewRecord] = verifiedPhotos.map { item in
        ArtworkReviewRecord(
            instrumentID: item.id,
            instrumentName: item.name,
            status: .approvedAfterReview,
            risk: "REAL PHOTO",
            requiredChecks: [
                "逐檔來源頁、作者與授權已保存",
                "實拍主體與樂器名稱、基本形制相符",
                "App 圖片只等比縮放與留白，未生成或重繪樂器"
            ]
        )
    } + [
        ArtworkReviewRecord(
            instrumentID: "paigu",
            instrumentName: "排鼓",
            status: .needsRegeneration,
            risk: "BLOCKED",
            requiredChecks: [
                "需取得可商用的整組排鼓實拍授權",
                "不得以單顆堂鼓或一般鼓組代替",
                "香港音樂事務處圖片只作形制參照，未取得書面許可不得包入"
            ]
        )
    ]

    static let highRiskIDs: Set<String> = ["paigu"]

    static func record(for instrumentID: String) -> ArtworkReviewRecord? {
        records.first { $0.instrumentID == instrumentID }
    }

    static func record(for instrument: Instrument) -> ArtworkReviewRecord? {
        record(for: instrument.id)
    }
}
