import SwiftUI

struct InstrumentsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @State private var selectedSectionID: String?
    @State private var searchText = ""

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: isRegularWidth ? 230 : 158, maximum: isRegularWidth ? 310 : .infinity),
                spacing: isRegularWidth ? 18 : 14
            )
        ]
    }

    private var filteredInstruments: [Instrument] {
        let scoped = store.instruments(in: selectedSectionID)
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return scoped
        }

        return scoped.filter {
            $0.nameZh.localizedStandardContains(searchText)
                || $0.nameEn.localizedStandardContains(searchText)
                || $0.descriptionBriefZh.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SectionFilterBar(sections: store.sections, selectedSectionID: $selectedSectionID)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: isRegularWidth ? 18 : 14) {
                        ForEach(filteredInstruments) { instrument in
                            NavigationLink {
                                InstrumentDetailView(instrument: instrument)
                            } label: {
                                InstrumentCard(
                                    instrument: instrument,
                                    section: store.section(for: instrument.sectionId),
                                    isFavorite: progressStore.isFavorite(instrument)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(isRegularWidth ? 24 : 16)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("樂器圖鑑")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜尋樂器、英文名或描述")
        }
    }
}

private struct InstrumentCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let instrument: Instrument
    let section: OrchestraSection?
    let isFavorite: Bool

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                InstrumentArtwork(instrument: instrument)
                    .frame(height: isRegularWidth ? 178 : 150)

                VStack(alignment: .leading, spacing: 5) {
                    if let section {
                        SectionBadge(section: section)
                    }

                    Text(instrument.nameZh)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(12)

                if isFavorite {
                    Image(systemName: "bookmark.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.gold)
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(instrument.nameEn)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(instrument.descriptionBriefZh)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(isRegularWidth ? 4 : 3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    TagLabel(text: instrument.beginnerDifficultyLabel, color: AppTheme.cinnabar)
                    TagLabel(text: instrument.rangeNotation, color: AppTheme.lapis)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InstrumentDetailView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @StateObject private var tonePlayer = TonePlayer()

    let instrument: Instrument

    private var section: OrchestraSection? {
        store.section(for: instrument.sectionId)
    }

    private var isPlaying: Bool {
        tonePlayer.activeInstrumentID == instrument.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                auditionButton
                professionalTraining
                description
                facts
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .navigationTitle(instrument.nameZh)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                progressStore.toggleFavorite(instrument)
            } label: {
                Image(systemName: progressStore.isFavorite(instrument) ? "bookmark.fill" : "bookmark")
            }
            .accessibilityLabel(progressStore.isFavorite(instrument) ? "取消收藏" : "收藏樂器")
        }
        .onDisappear {
            tonePlayer.stop()
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            InstrumentArtwork(instrument: instrument)
                .frame(height: 280)

            VStack(alignment: .leading, spacing: 9) {
                if let section {
                    SectionBadge(section: section)
                }

                Text(instrument.nameZh)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(instrument.nameEn)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))

                Text(instrument.descriptionBriefZh)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var auditionButton: some View {
        Button {
            isPlaying ? tonePlayer.stop() : tonePlayer.play(instrument: instrument)
        } label: {
            Label(isPlaying ? "停止離線聲音" : "試聽離線聲音", systemImage: isPlaying ? "stop.fill" : "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(section.map { Color(hex: $0.colorHex) } ?? AppTheme.cinnabar)
    }

    private var professionalTraining: some View {
        Group {
            if premiumStore.isProUnlocked {
                AppSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pro 音色拆解", systemImage: "waveform.path")
                            .font(.headline)

                        Text("先聽主音高 \(instrument.rangeNotation)，再抓 \(instrument.playingTechniqueZh) 的起音與尾音。進階練習時，把它和 \(instrument.famousPiecesZh) 的句法一起記憶。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                PremiumTeaserCard(feature: .audioPack, isUnlocked: false)
            }
        }
    }

    private var description: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("詳細介紹")
                    .font(.headline)

                Text(instrument.descriptionFullZh)
                    .font(.body)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var facts: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("演奏資訊")
                    .font(.headline)
                    .padding(.bottom, 4)

                InfoRow(title: "音域", value: "\(instrument.rangeZh)（\(instrument.rangeNotation)）")
                InfoRow(title: "技法", value: instrument.playingTechniqueZh)
                InfoRow(title: "定弦", value: instrument.tuningZh)
                InfoRow(title: "名曲", value: instrument.famousPiecesZh)
                InfoRow(title: "入門難度", value: instrument.beginnerDifficultyLabel)
                InfoRow(title: "進階特性", value: instrument.difficultyLevelAdvanced.zhDifficultyLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
