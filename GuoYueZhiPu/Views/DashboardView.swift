import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @EnvironmentObject private var premiumStore: PremiumStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    learningSnapshot
                    sectionOverview
                    todayRoute
                    featuredListening
                    premiumStrip
                }
                .padding(16)
                .padding(.bottom, 92)
            }
            .background(AppTheme.background)
            .navigationTitle(store.appData.metadata.appName)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularWidthHero
            } else {
                compactWidthHero
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("國樂團練習室，樂器圖鑑、名曲導聽、專業聽辨")
    }

    private var compactWidthHero: some View {
        ZStack(alignment: .bottomLeading) {
            BrandHeroImage(height: 235)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 8) {
                PremiumPill(text: premiumStore.isProUnlocked ? "Pro 已啟用" : "免費入門")
                Text("版本 \(store.appData.metadata.version)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.42), in: Capsule())
            }
            .padding(16)
        }
    }

    private var regularWidthHero: some View {
        GeometryReader { proxy in
            let artworkWidth = min(proxy.size.width * 0.43, 520)

            HStack(spacing: 0) {
                Image("brand_hero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: artworkWidth, height: 320)

                VStack(alignment: .leading, spacing: 16) {
                    Label("專業國樂學習工具", systemImage: "music.quarternote.3")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.gold)

                    Text("國樂團練習室")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(.white)

                    Text("樂器圖鑑 · 名曲導聽 · 專業聽辨")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))

                    Text("23 種樂器，依吹管、彈撥、拉弦與打擊四大聲部建立完整學習路線。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        PremiumPill(text: premiumStore.isProUnlocked ? "Pro 已啟用" : "免費入門")
                        Text("版本 \(store.appData.metadata.version)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.30), in: Capsule())
                    }
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 320)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#052E2A"), Color(hex: "#102420")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(height: 320)
    }

    private var learningSnapshot: some View {
        HStack(spacing: 8) {
            CompactMetricTile(title: "樂器", value: "\(store.instruments.count)", systemImage: "music.note", color: AppTheme.jade)
            CompactMetricTile(title: "課程", value: "\(progressStore.completedLessonIDs.count)", systemImage: "checkmark.seal", color: AppTheme.cinnabar)
            CompactMetricTile(title: "收藏", value: "\(progressStore.favoriteInstrumentIDs.count)", systemImage: "bookmark", color: AppTheme.lapis)
            CompactMetricTile(title: "佳績", value: "\(progressStore.bestQuizScore)", systemImage: "target", color: AppTheme.gold)
        }
        .accessibilityElement(children: .contain)
    }

    private var sectionOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("四大聲部")
                        .font(.title3.weight(.bold))
                    Text("點進聲部，再選擇每一件樂器")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "hand.tap")
                    .foregroundStyle(AppTheme.cinnabar)
            }

            HStack(alignment: .center, spacing: 8) {
                ForEach(store.sections) { section in
                    NavigationLink {
                        SectionInstrumentListView(section: section)
                    } label: {
                        SectionDashboardTile(section: section)
                    }
                    .buttonStyle(.plain)
                }
            }
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
                            Label("看 \(instrument.nameZh)", systemImage: "music.note.list")
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
        }
    }

    private var routeCopy: String {
        if progressStore.completedLessonIDs.isEmpty {
            return "先從四大聲部建立編制概念，再挑一件樂器閱讀形制、技法與真實音源說明。"
        }
        if progressStore.bestQuizScore < max(store.quizzes.count / 2, 1) {
            return "你已開始累積課程進度，下一步建議用樂器分類題庫補強聲部、定弦與技法判讀。"
        }
        return "基礎脈絡已經穩定，可以進入已取得授權的實器聽辨與完整 Pro 題庫。"
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

    private var featuredListening: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日導聽")
                .font(.title3.weight(.bold))

            if let piece = store.pieces.first {
                NavigationLink {
                    PieceDetailView(piece: piece)
                } label: {
                    AppSurface {
                        HStack(spacing: 14) {
                            Image(systemName: "text.book.closed.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(AppTheme.cinnabar)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(piece.titleZh)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(piece.composerZh) · \(piece.moodZh) · \(piece.durationMinutes) 分")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("本頁提供作品背景與聽辨線索；未授權曲目不提供音檔。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)
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
        NavigationLink {
            PremiumView()
        } label: {
            PremiumTeaserCard(feature: .instrumentDrills, isUnlocked: premiumStore.isProUnlocked)
        }
        .buttonStyle(.plain)
    }
}

private struct CompactMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.14), in: Circle())
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(color.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct SectionDashboardTile: View {
    let section: OrchestraSection

    private var color: Color { Color(hex: section.colorHex) }

    var body: some View {
        VStack(spacing: 9) {
            Text(section.ordinal)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.20), in: Circle())

            Text(section.nameZh)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.72)

            Text("\(section.instrumentCount) 件")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.80))
        }
        .frame(maxWidth: .infinity, minHeight: 116)
        .padding(.horizontal, 7)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [color.opacity(0.96), color.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: color.opacity(0.18), radius: 9, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
