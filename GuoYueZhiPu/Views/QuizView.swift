import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @State private var currentIndex = 0
    @State private var selectedIndex: Int?
    @State private var score = 0
    @State private var isFinished = false

    private var question: QuizQuestion? {
        store.quizzes.indices.contains(currentIndex) ? store.quizzes[currentIndex] : nil
    }

    var body: some View {
        Group {
            if store.quizzes.isEmpty {
                EmptyStateView(title: "尚無題目", message: "資料集中目前沒有測驗題。", systemImage: "questionmark.circle")
            } else if isFinished {
                resultView
            } else if let question {
                quizContent(question)
            }
        }
    }

    private func quizContent(_ question: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                progress

                VStack(alignment: .leading, spacing: 14) {
                    TagLabel(text: question.difficulty.zhDifficultyLabel, color: Color(hex: "#9B2C1F"))

                    Text(question.questionZh)
                        .font(.title2.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 10) {
                    ForEach(question.options.indices, id: \.self) { index in
                        answerButton(for: question, at: index)
                    }
                }

                if let selectedIndex {
                    explanation(for: question, selectedIndex: selectedIndex)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("第 \(currentIndex + 1) 題")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(currentIndex + 1) / \(store.quizzes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(store.quizzes.count))
                .tint(Color(hex: "#3D5A48"))
        }
    }

    private func answerButton(for question: QuizQuestion, at index: Int) -> some View {
        let isSelected = selectedIndex == index
        let isCorrect = question.correctIndex == index
        let shouldReveal = selectedIndex != nil
        let borderColor: Color = shouldReveal && isCorrect
            ? Color(hex: "#2E7D4F")
            : (isSelected ? Color(hex: "#9B2C1F") : Color(.separator))

        return Button {
            choose(index, for: question)
        } label: {
            HStack(spacing: 12) {
                Text(question.options[index].textZh)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if shouldReveal && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#2E7D4F"))
                } else if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(hex: "#9B2C1F"))
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: shouldReveal || isSelected ? 1.5 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(selectedIndex != nil)
    }

    private func explanation(for question: QuizQuestion, selectedIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(selectedIndex == question.correctIndex ? "答對了" : "再聽一次就會更清楚", systemImage: selectedIndex == question.correctIndex ? "checkmark.seal" : "lightbulb")
                .font(.headline)
                .foregroundStyle(selectedIndex == question.correctIndex ? Color(hex: "#2E7D4F") : Color(hex: "#9B2C1F"))

            Text(question.explanationZh)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(5)

            Button {
                goNext()
            } label: {
                Label(currentIndex == store.quizzes.count - 1 ? "看結果" : "下一題", systemImage: "arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#3D5A48"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: "seal.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Color(hex: "#C9A227"))

            Text("完成測驗")
                .font(.largeTitle.weight(.bold))

            Text("\(score) / \(store.quizzes.count)")
                .font(.title.weight(.bold))
                .foregroundStyle(Color(hex: "#3D5A48"))

            if progressStore.quizAttempts > 0 {
                Text("最佳紀錄 \(progressStore.bestQuizScore) 題 · 已練習 \(progressStore.quizAttempts) 次")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(resultMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                restart()
            } label: {
                Label("重新測驗", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#9B2C1F"))
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var resultMessage: String {
        let ratio = Double(score) / Double(max(store.quizzes.count, 1))
        if ratio >= 0.85 {
            return "你已經能辨認主要聲部與代表曲目。"
        } else if ratio >= 0.55 {
            return "基礎脈絡已經建立，可以回到樂器圖鑑補強細節。"
        } else {
            return "先從四大聲部與代表樂器開始，下一輪會明顯更順。"
        }
    }

    private func choose(_ index: Int, for question: QuizQuestion) {
        guard selectedIndex == nil else { return }
        selectedIndex = index
        if index == question.correctIndex {
            score += 1
        }
    }

    private func goNext() {
        if currentIndex == store.quizzes.count - 1 {
            progressStore.recordQuiz(score: score)
            isFinished = true
        } else {
            currentIndex += 1
            selectedIndex = nil
        }
    }

    private func restart() {
        currentIndex = 0
        selectedIndex = nil
        score = 0
        isFinished = false
    }
}
