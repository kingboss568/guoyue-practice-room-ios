import SwiftUI

struct PiecesView: View {
    @EnvironmentObject private var store: OrchestraStore
    @State private var mode: LibraryMode = .pieces
    @State private var searchText = ""
    @State private var selectedInstrument = "全部樂器"
    @State private var selectedComposer = "全部作曲家"
    @State private var selectedEra = "全部年代"

    private var instruments: [String] {
        ["全部樂器"] + Array(Set(store.pieces.map(\.mainInstrumentZh))).sorted()
    }

    private var composers: [String] {
        ["全部作曲家"] + Array(Set(store.pieces.map(\.composerZh))).sorted()
    }

    private var eras: [String] {
        ["全部年代"] + Array(Set(store.pieces.map(\.eraZh))).sorted()
    }

    private var filteredPieces: [Piece] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.pieces.filter { piece in
            let matchesInstrument = selectedInstrument == "全部樂器" || piece.mainInstrumentZh == selectedInstrument
            let matchesComposer = selectedComposer == "全部作曲家" || piece.composerZh == selectedComposer
            let matchesEra = selectedEra == "全部年代" || piece.eraZh == selectedEra
            let matchesSearch = query.isEmpty
                || piece.titleZh.localizedStandardContains(query)
                || piece.titleEn.localizedStandardContains(query)
                || piece.composerZh.localizedStandardContains(query)
                || piece.mainInstrumentZh.localizedStandardContains(query)
                || piece.themes.contains { $0.localizedStandardContains(query) }
            return matchesInstrument && matchesComposer && matchesEra && matchesSearch
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

    private var filteredLinks: [GuoyueLink] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return GuoyueLink.catalog }
        return GuoyueLink.catalog.filter {
            $0.title.localizedStandardContains(query)
                || $0.organization.localizedStandardContains(query)
                || $0.detail.localizedStandardContains(query)
                || $0.category.rawValue.localizedStandardContains(query)
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

                LibrarySearchField(text: $searchText, prompt: mode.searchPrompt)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                switch mode {
                case .pieces:
                    PieceFilterBar(
                        instruments: instruments,
                        composers: composers,
                        eras: eras,
                        selectedInstrument: $selectedInstrument,
                        selectedComposer: $selectedComposer,
                        selectedEra: $selectedEra
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    if filteredPieces.isEmpty {
                        EmptyLibraryRow(title: "找不到符合條件的曲目", detail: "請放寬樂器、作曲家或年代篩選。", icon: "line.3.horizontal.decrease.circle")
                    }
                    ForEach(filteredPieces) { piece in
                        NavigationLink {
                            PieceDetailView(piece: piece)
                        } label: {
                            PieceRow(piece: piece)
                        }
                    }
                case .musicians:
                    if filteredMusicians.isEmpty {
                        EmptyLibraryRow(title: "找不到名家", detail: "可搜尋姓名、別名或專業角色。", icon: "person.crop.circle.badge.questionmark")
                    }
                    ForEach(filteredMusicians) { musician in
                        NavigationLink {
                            MusicianDetailView(musician: musician)
                        } label: {
                            MusicianRow(musician: musician)
                        }
                    }
                case .links:
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("\(filteredLinks.count) 個專業資源入口", systemImage: "globe.asia.australia.fill")
                                .font(.headline)
                                .foregroundStyle(AppTheme.cinnabar)

                            Text("以政府、職業國樂團、公共典藏與可稽核研究資源為主。外部網站內的樂譜、圖片和錄音各有授權條件，不代表 App 可自由轉載。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }

                    ForEach(GuoyueLinkCategory.allCases) { category in
                        let links = filteredLinks.filter { $0.category == category }
                        if !links.isEmpty {
                            Section(category.rawValue) {
                                ForEach(links) { link in
                                    Link(destination: link.url) {
                                        RelatedLinkRow(link: link)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("國樂樂庫")
            .onChange(of: mode) { _ in searchText = "" }
        }
    }
}

private struct LibrarySearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel(prompt)

            if !text.isEmpty {
                Button("清除搜尋", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.16), lineWidth: 1)
        }
    }
}

private enum LibraryMode: String, CaseIterable, Identifiable {
    case pieces = "名曲"
    case musicians = "名家"
    case links = "連結"

    var id: String { rawValue }

    var searchPrompt: String {
        switch self {
        case .pieces: return "搜尋曲目、作曲家、樂器或主題"
        case .musicians: return "搜尋名家、別名或專業角色"
        case .links: return "搜尋樂團、典藏、樂譜或教育資源"
        }
    }
}

private struct PieceFilterBar: View {
    let instruments: [String]
    let composers: [String]
    let eras: [String]
    @Binding var selectedInstrument: String
    @Binding var selectedComposer: String
    @Binding var selectedEra: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("分類篩選", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.bold))
                Spacer()
                if hasActiveFilter {
                    Button("清除") {
                        selectedInstrument = "全部樂器"
                        selectedComposer = "全部作曲家"
                        selectedEra = "全部年代"
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterMenu(title: selectedInstrument, systemImage: "music.note", values: instruments, selection: $selectedInstrument)
                    FilterMenu(title: selectedComposer, systemImage: "person.wave.2", values: composers, selection: $selectedComposer)
                    FilterMenu(title: selectedEra, systemImage: "clock", values: eras, selection: $selectedEra)
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var hasActiveFilter: Bool {
        selectedInstrument != "全部樂器" || selectedComposer != "全部作曲家" || selectedEra != "全部年代"
    }
}

private struct FilterMenu: View {
    let title: String
    let systemImage: String
    let values: [String]
    @Binding var selection: String

    var body: some View {
        Menu {
            ForEach(values, id: \.self) { value in
                Button {
                    selection = value
                } label: {
                    if selection == value {
                        Label(value, systemImage: "checkmark")
                    } else {
                        Text(value)
                    }
                }
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(AppTheme.paper, in: Capsule())
        }
    }
}

private struct EmptyLibraryRow: View {
    let title: String
    let detail: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private enum GuoyueLinkCategory: String, CaseIterable, Identifiable {
    case orchestras = "專業國樂團"
    case archives = "典藏與人物"
    case education = "樂器與教育"
    case scores = "樂譜與編制"
    case research = "錄音與研究"

    var id: String { rawValue }
}

private struct GuoyueLink: Identifiable {
    let title: String
    let organization: String
    let detail: String
    let category: GuoyueLinkCategory
    let url: URL

    var id: String { url.absoluteString }

    static let catalog: [GuoyueLink] = [
        .init(title: "臺灣國樂團 NCO", organization: "國立傳統藝術中心", detail: "樂團簡介、樂季手冊與展演資訊。", category: .orchestras, url: URL(string: "https://www.ncfta.gov.tw/nco_72.html")!),
        .init(title: "臺北市立國樂團 TCO", organization: "臺北市政府", detail: "音樂會、教育推廣、國樂作品與出版資源。", category: .orchestras, url: URL(string: "https://www.tco.gov.taipei/")!),
        .init(title: "桃園市國樂團", organization: "桃園市文化基金會", detail: "展演資訊、器樂比賽與工作坊。", category: .orchestras, url: URL(string: "https://tyuco.taoyuancf.org.tw/")!),
        .init(title: "高雄市國樂團", organization: "高雄市文化局", detail: "南臺灣職業國樂團與展演團隊資訊。", category: .orchestras, url: URL(string: "https://art-garden.khcc.gov.tw/introduction/team/181641")!),
        .init(title: "香港中樂團 HKCO", organization: "香港中樂團", detail: "職業中樂團編制、樂員、展演與環保胡琴資源。", category: .orchestras, url: URL(string: "https://www.hkco.org/tc/About-Hkco/About-Us.html")!),
        .init(title: "新加坡華樂團 SCO", organization: "Singapore Chinese Orchestra", detail: "樂團、教育推廣與數位典藏入口。", category: .orchestras, url: URL(string: "https://sco.com.sg/about-us/about-the-orchestra/")!),
        .init(title: "中央民族樂團 CNTO", organization: "中國文化和旅遊部直屬院團", detail: "國家級民族管弦樂隊、合唱隊、演出與公益推廣資訊。", category: .orchestras, url: URL(string: "https://www.cnto.net.cn/")!),
        .init(title: "澳門中樂團 OCHM", organization: "澳門樂團有限公司", detail: "樂季、音樂會、樂團與音樂家資訊。", category: .orchestras, url: URL(string: "https://www.ochm-macau.org/")!),
        .init(title: "上海民族樂團", organization: "上海大劇院藝術中心", detail: "上海民族樂團及所屬藝術中心的演出、節目與院團資訊。", category: .orchestras, url: URL(string: "https://www.sgtartsgroup.org.cn/index-cn/")!),
        .init(title: "傳藝典藏網", organization: "國立傳統藝術中心", detail: "傳統藝術文物、作曲家曲譜與臺灣國樂團成果典藏。", category: .archives, url: URL(string: "https://collections.ncfta.gov.tw/")!),
        .init(title: "臺灣音樂群像資料庫", organization: "臺灣音樂館", detail: "作曲家、指揮家、演奏家與傳統樂器人物資料。", category: .archives, url: URL(string: "https://musiciantw.ncfta.gov.tw/")!),
        .init(title: "臺灣音樂館館藏查詢", organization: "國立傳統藝術中心", detail: "查詢樂譜、書籍、視聽資料與音樂史料；使用前仍須確認各件權利。", category: .archives, url: URL(string: "https://www.ncfta.gov.tw/cp.aspx?n=4515")!),
        .init(title: "臺灣音樂館開放博物館", organization: "國立傳統藝術中心臺灣音樂館", detail: "瀏覽影音、文物與人物主題藏品，適合研究臺灣國樂脈絡。", category: .archives, url: URL(string: "https://tmi.openmuseum.tw/")!),
        .init(title: "傳藝典藏－國樂類", organization: "國立傳統藝術中心", detail: "直接進入國樂手稿、曲譜、照片與計畫成果的主題分類。", category: .archives, url: URL(string: "https://collections.ncfta.gov.tw/pages/list/categories.aspx?c=008")!),
        .init(title: "SCO 數位典藏文章", organization: "Singapore Chinese Orchestra", detail: "樂團歷史、作品、作曲家與華樂發展的研究型文章入口。", category: .archives, url: URL(string: "https://archives.sco.com.sg/blogs/")!),
        .init(title: "中國樂器指南", organization: "香港康樂及文化事務署音樂事務處", detail: "樂器形制、國樂團分組與官方教育參照。", category: .education, url: URL(string: "https://www.lcsd.gov.hk/en/mo/musicguide/en/chinese_musical.html")!),
        .init(title: "臺灣的器樂－國樂", organization: "國立臺灣藝術教育館", detail: "八音分類、傳統樂器與臺灣音樂教育入門。", category: .education, url: URL(string: "https://web.arte.gov.tw/traditionalmusic/4/4.htm")!),
        .init(title: "TCO 國樂研習營", organization: "臺北市立國樂團", detail: "國樂社團學生、演奏觀念與暑期研習的官方教育資訊。", category: .education, url: URL(string: "https://www.tco.gov.taipei/cp.aspx?n=F1908449D2E0B329")!),
        .init(title: "香港音樂事務處資源中心", organization: "香港康樂及文化事務署", detail: "中樂合奏譜、教材、視聽參考與中國樂器分類資源。", category: .education, url: URL(string: "https://www.lcsd.gov.hk/tc/mo/morc.html")!),
        .init(title: "香港教育局中國器樂教材", organization: "香港教育局", detail: "中國器樂、廣東音樂、江南絲竹及音樂術語的官方教學資源。", category: .education, url: URL(string: "https://www.edb.gov.hk/en/curriculum-development/kla/arts-edu/resources/mus-curri/index.html")!),
        .init(title: "學校華樂團參考指南", organization: "新加坡教育部", detail: "含樂團管理、評量、樂器資源指南與建議曲目；PDF 英文資料。", category: .education, url: URL(string: "https://www.moe.gov.sg/-/media/moe/document/programmes/chinese-orchestra.pdf")!),
        .init(title: "臺北市立國樂團樂譜資源", organization: "臺北市立國樂團", detail: "國樂曲譜與出版品查詢；使用與借閱仍以各頁授權為準。", category: .scores, url: URL(string: "https://www.tco.gov.taipei/News.aspx?n=BB40E237A2400090&sms=F8145F0F09396E39")!),
        .init(title: "國樂團總譜格式、樂器表與音域", organization: "Singapore Chinese Orchestra", detail: "作曲與編曲用的樂器名單、順序與音域 PDF。", category: .scores, url: URL(string: "https://www.sco.com.sg/images/pdf/Score-Format-Instrument-List-and-Range.pdf")!),
        .init(title: "SCO 教育樂譜", organization: "Singapore Chinese Orchestra", detail: "教育與非職業樂團可查詢的簡化華樂總譜；每首仍依頁面條件使用。", category: .scores, url: URL(string: "https://sco.com.sg/resources/music-scores/")!),
        .init(title: "中國傳統樂器錄音資料集", organization: "Zenodo", detail: "CC BY 4.0 的實器單樂器片段；App 中部分試聽的可稽核來源。", category: .research, url: URL(string: "https://zenodo.org/records/8012071")!),
        .init(title: "Wikimedia Commons 中國樂器素材", organization: "Wikimedia Commons", detail: "可查看實拍、錄音與逐檔授權；下載前必須檢查每個檔案頁。", category: .research, url: URL(string: "https://commons.wikimedia.org/wiki/Category:Chinese_musical_instruments")!),
        .init(title: "ChMusic 樂器辨識研究", organization: "arXiv / ChMusic authors", detail: "11 種實器、55 段研究資料的論文入口；可下載不等於可在商業 App 再散布。", category: .research, url: URL(string: "https://arxiv.org/abs/2108.08470")!)
    ]
}

private struct RelatedLinkRow: View {
    let link: GuoyueLink

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "link.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.cinnabar)
            VStack(alignment: .leading, spacing: 5) {
                Text(link.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(link.organization)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.jade)
                Text(link.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
    }
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
