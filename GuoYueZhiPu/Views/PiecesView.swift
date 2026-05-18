import SwiftUI

struct PiecesView: View {
    @EnvironmentObject private var store: OrchestraStore
    @State private var mode: LibraryMode = .pieces
    @State private var searchText = ""

    private var filteredPieces: [Piece] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.pieces
        }
        return store.pieces.filter {
            $0.titleZh.localizedStandardContains(searchText)
                || $0.titleEn.localizedStandardContains(searchText)
                || $0.composerZh.localizedStandardContains(searchText)
        }
    }

    private var filteredMusicians: [Musician] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.musicians
        }
        return store.musicians.filter {
            $0.nameZh.localizedStandardContains(searchText)
                || ($0.aliasZh?.localizedStandardContains(searchText) ?? false)
                || $0.roleZh.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("內容", selection: $mode) {
                    ForEach(LibraryMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                switch mode {
                case .pieces:
                    ForEach(filteredPieces) { piece in
                        NavigationLink {
                            PieceDetailView(piece: piece)
                        } label: {
                            PieceRow(piece: piece)
                        }
                    }
                case .musicians:
                    ForEach(filteredMusicians) { musician in
                        NavigationLink {
                            MusicianDetailView(musician: musician)
                        } label: {
                            MusicianRow(musician: musician)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("名曲名家")
            .searchable(text: $searchText, prompt: "搜尋曲目、作曲家或名家")
        }
    }
}

private enum LibraryMode: String, CaseIterable, Identifiable {
    case pieces = "名曲"
    case musicians = "名家"

    var id: String { rawValue }
}

private struct PieceRow: View {
    let piece: Piece

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(piece.titleZh)
                    .font(.headline)

                Spacer()

                Text("\(piece.durationMinutes) 分")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(piece.composerZh)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(piece.descriptionZh)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                TagLabel(text: piece.eraZh, color: Color(hex: "#9B2C1F"))
                TagLabel(text: piece.moodZh, color: Color(hex: "#3D5A48"))
                TagLabel(text: piece.mainInstrumentZh, color: Color(hex: "#4B5F8F"))
            }
        }
        .padding(.vertical, 5)
    }
}

private struct MusicianRow: View {
    let musician: Musician

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(musician.displayName)
                    .font(.headline)
                Spacer()
                Text(musician.lifespanZh)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(musician.roleZh)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(musician.descriptionZh)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            TagLabel(text: musician.bioTagZh, color: Color(hex: "#6B4E2E"))
        }
        .padding(.vertical, 5)
    }
}

struct PieceDetailView: View {
    @EnvironmentObject private var store: OrchestraStore
    let piece: Piece

    var relatedMusicians: [Musician] {
        piece.relatedMusicians.compactMap { store.musician(for: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                bodySection(title: "作品背景", text: piece.historyZh, icon: "clock")
                bodySection(title: "聆聽線索", text: piece.listeningGuidanceZh, icon: "ear")

                if !relatedMusicians.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("相關名家")
                            .font(.headline)

                        ForEach(relatedMusicians) { musician in
                            NavigationLink {
                                MusicianDetailView(musician: musician)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(musician.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(musician.roleZh)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(piece.titleZh)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(piece.titleZh)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            Text(piece.titleEn)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(piece.descriptionZh)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(5)

            HStack(spacing: 8) {
                TagLabel(text: piece.composerZh, color: Color(hex: "#9B2C1F"))
                TagLabel(text: piece.ensembleType == "solo" ? "獨奏" : "合奏", color: Color(hex: "#3D5A48"))
                TagLabel(text: "\(piece.durationMinutes) 分", color: Color(hex: "#4B5F8F"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func bodySection(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(text)
                .font(.body)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MusicianDetailView: View {
    @EnvironmentObject private var store: OrchestraStore
    let musician: Musician

    private var works: [Piece] {
        store.works(for: musician)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    TagLabel(text: musician.bioTagZh, color: Color(hex: "#6B4E2E"))

                    Text(musician.displayName)
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(musician.lifespanZh) · \(musician.roleZh)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(musician.descriptionZh)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                bodySection(title: "生平", text: musician.fullBioZh, icon: "person.text.rectangle")
                bodySection(title: "意義", text: musician.significanceZh, icon: "sparkles")

                if !works.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("代表作品")
                            .font(.headline)

                        ForEach(works) { piece in
                            NavigationLink {
                                PieceDetailView(piece: piece)
                            } label: {
                                HStack {
                                    Text(piece.titleZh)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(piece.mainInstrumentZh)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(musician.nameZh)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bodySection(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(text)
                .font(.body)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
