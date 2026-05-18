import Foundation

@MainActor
final class LearningProgressStore: ObservableObject {
    @Published private(set) var favoriteInstrumentIDs: Set<String>
    @Published private(set) var completedLessonIDs: Set<String>
    @Published private(set) var bestQuizScore: Int
    @Published private(set) var quizAttempts: Int

    private let defaults: UserDefaults

    private enum Key {
        static let favorites = "learning.favoriteInstrumentIDs"
        static let completedLessons = "learning.completedLessonIDs"
        static let bestQuizScore = "learning.bestQuizScore"
        static let quizAttempts = "learning.quizAttempts"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favoriteInstrumentIDs = Set(defaults.stringArray(forKey: Key.favorites) ?? [])
        completedLessonIDs = Set(defaults.stringArray(forKey: Key.completedLessons) ?? [])
        bestQuizScore = defaults.integer(forKey: Key.bestQuizScore)
        quizAttempts = defaults.integer(forKey: Key.quizAttempts)
    }

    func toggleFavorite(_ instrument: Instrument) {
        if favoriteInstrumentIDs.contains(instrument.id) {
            favoriteInstrumentIDs.remove(instrument.id)
        } else {
            favoriteInstrumentIDs.insert(instrument.id)
        }
        defaults.set(Array(favoriteInstrumentIDs).sorted(), forKey: Key.favorites)
    }

    func isFavorite(_ instrument: Instrument) -> Bool {
        favoriteInstrumentIDs.contains(instrument.id)
    }

    func setLesson(_ lesson: Lesson, completed: Bool) {
        if completed {
            completedLessonIDs.insert(lesson.id)
        } else {
            completedLessonIDs.remove(lesson.id)
        }
        defaults.set(Array(completedLessonIDs).sorted(), forKey: Key.completedLessons)
    }

    func isLessonCompleted(_ lesson: Lesson) -> Bool {
        completedLessonIDs.contains(lesson.id)
    }

    func recordQuiz(score: Int) {
        bestQuizScore = max(bestQuizScore, score)
        quizAttempts += 1
        defaults.set(bestQuizScore, forKey: Key.bestQuizScore)
        defaults.set(quizAttempts, forKey: Key.quizAttempts)
    }

    func lessonCompletionRatio(totalLessons: Int) -> Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessonIDs.count) / Double(totalLessons)
    }
}
