import SwiftUI

struct LessonsView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore

    var body: some View {
        List(store.lessons) { lesson in
            NavigationLink {
                LessonDetailView(lesson: lesson)
            } label: {
                LessonRow(lesson: lesson, isCompleted: progressStore.isLessonCompleted(lesson))
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCompleted ? AppTheme.jade : AppTheme.cinnabar)
                    .frame(width: 34, height: 34)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(lesson.order)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(lesson.titleZh)
                        .font(.headline)
                    Spacer()
                    Text("\(lesson.durationMinutes) 分")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(lesson.learningObjectivesZh.first ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                TagLabel(text: lesson.difficultyLevel.zhDifficultyLabel, color: Color(hex: "#3D5A48"))
            }
        }
        .padding(.vertical, 5)
    }
}

struct LessonDetailView: View {
    @EnvironmentObject private var progressStore: LearningProgressStore

    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                objectives
                content
                review
                completeButton
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(lesson.titleZh)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("第 \(lesson.order) 課")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "#9B2C1F"))

            Text(lesson.titleZh)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                TagLabel(text: "\(lesson.durationMinutes) 分", color: Color(hex: "#4B5F8F"))
                TagLabel(text: lesson.difficultyLevel.zhDifficultyLabel, color: Color(hex: "#3D5A48"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var objectives: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("學習目標", systemImage: "target")
                .font(.headline)

            ForEach(lesson.learningObjectivesZh, id: \.self) { objective in
                Label(objective, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(lesson.contentBlocks.enumerated()), id: \.offset) { _, block in
                switch block.type {
                case "intro":
                    Text(block.textZh ?? "")
                        .font(.title3.weight(.semibold))
                        .lineSpacing(6)
                case "section":
                    Text(block.titleZh ?? "")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#9B2C1F"))
                        .padding(.top, 4)
                case "insight":
                    Text(block.textZh ?? "")
                        .font(.body.italic())
                        .lineSpacing(6)
                        .padding(.leading, 12)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#C9A227"))
                                .frame(width: 4)
                        }
                default:
                    Text(block.textZh ?? "")
                        .font(.body)
                        .lineSpacing(7)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("複習", systemImage: "questionmark.circle")
                .font(.headline)

            ForEach(Array(lesson.reviewQuestions.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(index + 1). \(item.q)")
                        .font(.subheadline.weight(.semibold))
                    Text(item.a)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var completeButton: some View {
        let completed = progressStore.isLessonCompleted(lesson)
        return Button {
            progressStore.setLesson(lesson, completed: !completed)
        } label: {
            Label(completed ? "標記為尚未完成" : "完成本課", systemImage: completed ? "arrow.uturn.backward" : "checkmark.seal.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(completed ? AppTheme.lapis : AppTheme.jade)
    }
}
