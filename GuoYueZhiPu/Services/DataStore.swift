import Foundation
import Combine

@MainActor
final class OrchestraStore: ObservableObject {
    @Published private(set) var appData: OrchestraData = .empty
    @Published private(set) var isLoaded = false
    @Published private(set) var loadError: String?

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(
            forResource: "chinese_orchestra_data_export",
            withExtension: "json"
        ) else {
            loadError = "找不到本機資料檔 chinese_orchestra_data_export.json"
            isLoaded = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            appData = try decoder.decode(OrchestraData.self, from: data)
            loadError = nil
            isLoaded = true
        } catch {
            loadError = error.localizedDescription
            isLoaded = false
        }
    }

    var sections: [OrchestraSection] {
        appData.sections.sorted { $0.ordinalNumber < $1.ordinalNumber }
    }

    var instruments: [Instrument] {
        appData.instruments
    }

    var pieces: [Piece] {
        appData.pieces
    }

    var musicians: [Musician] {
        appData.musicians
    }

    var lessons: [Lesson] {
        appData.lessons.sorted { $0.order < $1.order }
    }

    var quizzes: [QuizQuestion] {
        appData.quizzes
    }

    func section(for id: String) -> OrchestraSection? {
        sections.first { $0.id == id }
    }

    func instruments(in sectionID: String?) -> [Instrument] {
        guard let sectionID else { return instruments }
        return instruments.filter { $0.sectionId == sectionID }
    }

    func musician(for id: String) -> Musician? {
        musicians.first { $0.id == id }
    }

    func piece(for id: String) -> Piece? {
        pieces.first { $0.id == id }
    }

    func works(for musician: Musician) -> [Piece] {
        musician.famousWorks.compactMap { piece(for: $0) }
    }
}
