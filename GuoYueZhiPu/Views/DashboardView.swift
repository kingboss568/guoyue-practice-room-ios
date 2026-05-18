import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @EnvironmentObject private var premiumStore: PremiumStore

    private let metricColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    learningSnapshot
                    todayRoute
                    sectionOverview
                    featuredListening
                    premiumStrip
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle(store.appData.metadata.appName)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            BrandHeroImage(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                Text("國樂團練習室")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.white)

                Text("從樂器圖鑑、名曲導聆到聽辨練習，一次建立華樂團的完整地圖。")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    PremiumPill(text: premiumStore.isProUnlocked ? "Pro 已啟用" : "免費下載")
                    Text("版本 \(store.appData.metadata.version)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.24), in: Capsule())
                }
            }
            .padding(18)
        }
    }

    private var learningSnapshot: some View {
        LazyVGrid(columns: metricColumns, spacing: 10) {
            MetricCapsule(title: "樂器圖鑑", value: "\(store.instruments.count)", systemImage: "music.note", color: AppTheme.jade)
            MetricCapsule(title: "完成課程", value: "\(progressStore.completedLessonIDs.count)/\(store.lessons.count)", systemImage: "checkmark.seal", color: AppTheme.cinnabar)
            MetricCapsule(title: "收藏樂器", value: "\(progressStore.favoriteInstrumentIDs.count)", systemImage: "bookmark", color: AppTheme.lapis)
            MetricCapsule(title: "最佳測驗", value: "\(progressStore.bestQuizScore)/\(store.quizzes.count)", systemImage: "target", color: AppTheme.gold)
        }
    }

    private var todayRoute: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 14) {
                Label("今日練習路線", systemImage: "map")
                    .font(.headline)

                ProgressView(value: progressStore.lessonCompletionRatio(totalLessons: store.lessons.count))
                    .tint(AppTheme.jade)

                Text(routeCopy)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    if let instrument = recommendedInstrument {
                        NavigationLink {
                            InstrumentDetailView(instrument: instrument)
                        } label: {
                            Label("練 \(instrument.nameZh)", systemImage: "play.circle")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.jade)
                    }

                    if let lesson = nextLesson {
                        NavigationLink {
                            LessonDetailView(lesson: lesson)
                        } label: {
                            Label("第 \(lesson.order) 課", systemImage: "book")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var routeCopy: String {
        if progressStore.completedLessonIDs.isEmpty {
            return "先用 6 分鐘建立國樂源流，再挑一件樂器試聽。免費版足夠入門，Pro 版會把這條路線延伸成更完整的聽辨計畫。"
        }
        if progressStore.bestQuizScore < max(store.quizzes.count / 2, 1) {
            return "你已開始累積課程進度，下一步建議補強聽辨題。先看提示再作答，會比死背樂器名稱更有效。"
        }
        return "基礎脈絡已經穩定，可以進入 Pro 的專家題庫，把技法、音色與代表曲目連在一起。"
    }

    private var recommendedInstrument: Instrument? {
        if let favoriteID = progressStore.favoriteInstrumentIDs.sorted().first {
            return store.instruments.first { $0.id == favoriteID }
        }
        return store.instruments.first
    }

    private var nextLesson: Lesson? {
        store.lessons.first { !progressStore.completedLessonIDs.contains($0.id) } ?? store.lessons.first
    }

    private var sectionOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("四大聲部")
                .font(.headline)

            ForEach(store.sections) { section in
                AppSurface {
                    HStack(alignment: .top, spacing: 12) {
                        Text(section.ordinal)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: section.colorHex), in: Circle())

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(section.nameZh)
                                    .font(.headline)
                                Text(section.nameEn)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(section.instrumentCount) 件")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: section.colorHex))
                            }

                            Text(section.blurbZh)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var featuredListening: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日聆聽")
                .font(.headline)

            if let piece = store.pieces.first {
                NavigationLink {
                    PieceDetailView(piece: piece)
                } label: {
                    AppSurface {
                        HStack(spacing: 14) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(AppTheme.cinnabar)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(piece.titleZh)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(piece.composerZh) · \(piece.moodZh) · \(piece.durationMinutes) 分")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var premiumStrip: some View {
        PremiumTeaserCard(feature: .studyPlan, isUnlocked: premiumStore.isProUnlocked)
    }
}
