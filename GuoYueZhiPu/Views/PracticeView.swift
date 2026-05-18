import SwiftUI

struct PracticeView: View {
    @State private var mode: PracticeMode = .lessons

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("練習模式", selection: $mode) {
                    ForEach(PracticeMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                switch mode {
                case .lessons:
                    LessonsView()
                case .quiz:
                    QuizView()
                case .pro:
                    ProDrillsView()
                }
            }
            .background(AppTheme.background)
            .navigationTitle("練功房")
        }
    }
}

private enum PracticeMode: String, CaseIterable, Identifiable {
    case lessons
    case quiz
    case pro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lessons:
            return "課程"
        case .quiz:
            return "測驗"
        case .pro:
            return "Pro"
        }
    }
}

private struct ProDrillsView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PremiumTeaserCard(feature: .expertDrills, isUnlocked: premiumStore.isProUnlocked)

                if premiumStore.isProUnlocked {
                    ForEach(drills) { drill in
                        AppSurface {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(drill.title, systemImage: drill.icon)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)

                                Text(drill.prompt)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(drill.answer)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(AppTheme.cinnabar)
                                    .padding(.top, 2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    lockedPreview
                }
            }
            .padding(16)
        }
        .background(AppTheme.background)
    }

    private var lockedPreview: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("解鎖後會出現的訓練")
                    .font(.headline)
                Text("系統會依照樂器聲部、代表名曲與課程進度，生成更接近考級與導聆需求的題目。免費版保留入門測驗，Pro 版補上深度訓練與複習路線。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var drills: [ProDrill] {
        let instruments = Array(store.instruments.prefix(4))
        return instruments.enumerated().map { index, instrument in
            ProDrill(
                id: instrument.id,
                icon: index.isMultiple(of: 2) ? "ear" : "waveform.path.ecg",
                title: "\(instrument.nameZh) 音色判讀",
                prompt: "聽到 \(instrument.rangeNotation) 附近、技法包含 \(instrument.playingTechniqueZh) 的聲音時，先判斷它屬於哪個聲部，再回想代表曲目。",
                answer: "提示：\(instrument.famousPiecesZh)"
            )
        }
    }
}

private struct ProDrill: Identifiable {
    let id: String
    let icon: String
    let title: String
    let prompt: String
    let answer: String
}
