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
    let pitchFrequencyHz: Double
    let audioWaveformType: String
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
    case expertDrills
    case concertMode
    case studyPlan
    case audioPack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expertDrills:
            return "專家級聽辨題庫"
        case .concertMode:
            return "舞台編制與聲部分析"
        case .studyPlan:
            return "個人化練習路線"
        case .audioPack:
            return "23 件樂器離線聲音包"
        }
    }

    var subtitle: String {
        switch self {
        case .expertDrills:
            return "從音色、技法、代表曲目三層次建立真正會聽的能力。"
        case .concertMode:
            return "用樂團座位、聲部功能與曲目情緒理解演出現場。"
        case .studyPlan:
            return "依收藏、課程與測驗結果整理下一步，不只是看資料。"
        case .audioPack:
            return "每件樂器都有本機生成聲音樣本，無網路也能練。"
        }
    }

    var systemImage: String {
        switch self {
        case .expertDrills:
            return "ear.badge.waveform"
        case .concertMode:
            return "music.note.house"
        case .studyPlan:
            return "map"
        case .audioPack:
            return "waveform"
        }
    }
}
