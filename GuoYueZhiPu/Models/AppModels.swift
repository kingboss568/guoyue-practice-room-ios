import Foundation

struct OrchestraData: Codable {
    let metadata: AppMetadata
    let sections: [OrchestraSection]
    let instruments: [Instrument]
    let pieces: [Piece]
    let musicians: [Musician]
    let lessons: [Lesson]
    let quizzes: [QuizQuestion]

    static let empty = OrchestraData(
        metadata: .empty,
        sections: [],
        instruments: [],
        pieces: [],
        musicians: [],
        lessons: [],
        quizzes: []
    )
}

struct AppMetadata: Codable {
    let appName: String
    let version: String
    let exportedDate: String
    let totalInstruments: Int
    let totalPieces: Int
    let languages: [String]

    static let empty = AppMetadata(
        appName: "國樂團練習室",
        version: "1.0.0",
        exportedDate: "",
        totalInstruments: 0,
        totalPieces: 0,
        languages: []
    )
}

struct OrchestraSection: Codable, Identifiable, Hashable {
    let id: String
    let nameZh: String
    let nameEn: String
    let ordinal: String
    let ordinalNumber: Int
    let blurbZh: String
    let descriptionZh: String
    let instrumentCount: Int
    let colorHex: String
}

struct Instrument: Codable, Identifiable, Hashable {
    let id: String
    let nameZh: String
    let nameEn: String
    let sectionId: String
    let descriptionBriefZh: String
    let descriptionFullZh: String
    let rangeZh: String
    let rangeNotation: String
    let playingTechniqueZh: String
    let tuningZh: String
    let famousPiecesZh: String
    let difficultyLevelBeginner: String
    let difficultyLevelAdvanced: String
    let imageUrlPlaceholder: String
    let audioSampleUrlPlaceholder: String

    var beginnerDifficultyLabel: String {
        difficultyLevelBeginner.zhDifficultyLabel
    }

    var artworkAssetName: String {
        "instrument_\(id)"
    }

    var audioFileName: String {
        id
    }
}

struct Piece: Codable, Identifiable, Hashable {
    let id: String
    let titleZh: String
    let titleEn: String
    let composerZh: String
    let yearComposed: Int?
    let durationMinutes: Int
    let eraZh: String
    let moodZh: String
    let mainInstrumentZh: String
    let ensembleType: String
    let descriptionZh: String
    let historyZh: String
    let listeningGuidanceZh: String
    let relatedMusicians: [String]
    let relatedPieces: [String]
    let themes: [String]
    let audioSampleUrl: String
    let scoreUrlPlaceholder: String
}

struct Musician: Codable, Identifiable, Hashable {
    let id: String
    let nameZh: String
    let aliasZh: String?
    let birthYear: Int
    let deathYear: Int?
    let lifespanZh: String
    let roleZh: String
    let specialtyZh: String
    let bioTagZh: String
    let descriptionZh: String
    let fullBioZh: String
    let significanceZh: String
    let famousWorks: [String]
    let relatedMusicians: [String]

    var displayName: String {
        if let aliasZh, !aliasZh.isEmpty {
            return "\(nameZh)（\(aliasZh)）"
        }
        return nameZh
    }
}

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    let order: Int
    let titleZh: String
    let durationMinutes: Int
    let difficultyLevel: String
    let learningObjectivesZh: [String]
    let contentBlocks: [LessonContentBlock]
    let reviewQuestions: [ReviewQuestion]
}

struct LessonContentBlock: Codable, Hashable {
    let type: String
    let titleZh: String?
    let textZh: String?
}

struct ReviewQuestion: Codable, Hashable {
    let q: String
    let a: String
}

struct QuizQuestion: Codable, Identifiable, Hashable {
    let id: String
    let questionZh: String
    let difficulty: String
    let options: [QuizOption]
    let correctIndex: Int
    let explanationZh: String
    let tags: [String]
}

struct QuizOption: Codable, Hashable {
    let textZh: String
    let textEn: String
}

extension String {
    var zhDifficultyLabel: String {
        switch self {
        case "easy":
            return "入門"
        case "moderate":
            return "中等"
        case "hard":
            return "進階"
        case "very_hard":
            return "專精"
        case "complex":
            return "複合技巧"
        case "beginner":
            return "初學"
        case "medium":
            return "中階"
        default:
            return self
        }
    }
}

enum PremiumFeature: String, Identifiable, CaseIterable {
    case instrumentDrills
    case foundationDrills
    case realAudioDrills
    case purchaseRestore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instrumentDrills:
            return "23 種樂器完整題庫"
        case .foundationDrills:
            return "230 題基礎知識"
        case .realAudioDrills:
            return "核准實器聽辨題"
        case .purchaseRestore:
            return "一次購買與恢復"
        }
    }

    var subtitle: String {
        switch self {
        case .instrumentDrills:
            return "每件樂器由免費 5 題升級為完整 50 題，含作答、解析與重練。"
        case .foundationDrills:
            return "解鎖四大聲部、形制、發聲、音域與編制的完整基礎題庫。"
        case .realAudioDrills:
            return "解鎖所有已取得商用授權且通過來源稽核的實器聽辨題。"
        case .purchaseRestore:
            return "非消耗性一次購買；更換裝置或重新安裝後可恢復購買。"
        }
    }

    var systemImage: String {
        switch self {
        case .instrumentDrills:
            return "list.number"
        case .foundationDrills:
            return "books.vertical"
        case .realAudioDrills:
            return "ear.badge.waveform"
        case .purchaseRestore:
            return "arrow.clockwise.circle"
        }
    }
}
