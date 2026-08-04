import SwiftUI

struct InstrumentsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @State private var selectedSectionID: String?
    @State private var searchText = ""

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: isRegularWidth ? 230 : 158, maximum: isRegularWidth ? 310 : .infinity), spacing: isRegularWidth ? 18 : 14)]
    }

    private var filteredInstruments: [Instrument] {
        let scoped = store.instruments(in: selectedSectionID)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return scoped }
        return scoped.filter {
            $0.nameZh.localizedStandardContains(query)
                || $0.nameEn.localizedStandardContains(query)
                || $0.descriptionBriefZh.localizedStandardContains(query)
                || $0.playingTechniqueZh.localizedStandardContains(query)
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
                    .padding(.bottom, 88)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("樂器圖鑑")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜尋樂器、英文名或技法")
        }
    }
}

struct SectionInstrumentListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    let section: OrchestraSection

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: horizontalSizeClass == .regular ? 230 : 158, maximum: 310), spacing: 14)]
    }

    private var instruments: [Instrument] {
        store.instruments(in: section.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppSurface {
                    HStack(alignment: .top, spacing: 14) {
                        Text(section.ordinal)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color(hex: section.colorHex), in: Circle())

                        VStack(alignment: .leading, spacing: 7) {
                            Text(section.nameZh)
                                .font(.title2.weight(.bold))
                            Text(section.descriptionZh)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("本聲部 \(instruments.count) 件樂器，每一張卡片都可點入。")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: section.colorHex))
                        }
                    }
                }

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(instruments) { instrument in
                        NavigationLink {
                            InstrumentDetailView(instrument: instrument)
                        } label: {
                            InstrumentCard(
                                instrument: instrument,
                                section: section,
                                isFavorite: progressStore.isFavorite(instrument)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .navigationTitle(section.nameZh)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InstrumentCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let instrument: Instrument
    let section: OrchestraSection?
    let isFavorite: Bool

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                InstrumentArtwork(instrument: instrument)
                    .frame(height: isRegularWidth ? 184 : 154)

                VStack(alignment: .leading, spacing: 6) {
                    if let section { SectionBadge(section: section) }
                    Text(instrument.nameZh)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(14)

                if isFavorite {
                    Image(systemName: "bookmark.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.gold)
                        .padding(14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(instrument.nameEn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }

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
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.16), lineWidth: 0.5)
        }
    }
}

struct InstrumentDetailView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var progressStore: LearningProgressStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @StateObject private var tonePlayer = TonePlayer()

    let instrument: Instrument

    private var section: OrchestraSection? { store.section(for: instrument.sectionId) }
    private var isPlaying: Bool { tonePlayer.activeInstrumentID == instrument.id }
    private var hasApprovedAudio: Bool { AudioSourceCatalog.approvedSource(for: instrument) != nil }
    private var externalDemonstration: ExternalInstrumentDemonstration? {
        ExternalInstrumentDemonstrationCatalog.reference(for: instrument)
    }
    private var guide: InstrumentStudyGuide { InstrumentStudyCatalog.guide(for: instrument, section: section) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                auditionButton
                if let statusMessage = tonePlayer.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                practiceEntry
                overview
                studyGuide
                facts
                sourceDisclosures
            }
            .padding(16)
            .padding(.bottom, 80)
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
        .onDisappear { tonePlayer.stop() }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            InstrumentArtwork(instrument: instrument, cornerRadius: 22)
                .frame(height: 300)

            VStack(alignment: .leading, spacing: 9) {
                if let section { SectionBadge(section: section) }
                Text(instrument.nameZh)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(.white)
                Text(instrument.nameEn)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.90))
                Text(instrument.descriptionBriefZh)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private var auditionButton: some View {
        if hasApprovedAudio {
            Button {
                isPlaying ? tonePlayer.stop() : tonePlayer.play(instrument: instrument)
            } label: {
                Label(
                    isPlaying ? "停止播放" : "試聽已授權實器片段",
                    systemImage: isPlaying ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(section.map { Color(hex: $0.colorHex) } ?? AppTheme.cinnabar)
        } else if let externalDemonstration {
            Link(destination: externalDemonstration.sourceURL) {
                Label("開啟原站實器示範", systemImage: "arrow.up.right.square")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(section.map { Color(hex: $0.colorHex) } ?? AppTheme.cinnabar)
            .accessibilityHint("離開 App，前往 (externalDemonstration.provider) 的來源頁")
        } else {
            Button {} label: {
                Label("實器錄音待取得授權", systemImage: "waveform.badge.exclamationmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(section.map { Color(hex: $0.colorHex) } ?? AppTheme.cinnabar)
            .disabled(true)
        }
    }

    private var practiceEntry: some View {
        NavigationLink {
            InstrumentPracticeOverview(instrument: instrument)
        } label: {
            AppSurface {
                HStack(spacing: 14) {
                    Image(systemName: "target")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.cinnabar)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.cinnabar.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(instrument.nameZh) 專項練功")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(premiumStore.isProUnlocked ? "50 題已全部開放" : "免費試做 5 題、Pro 解鎖完整 50 題")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var overview: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                Label("樂器概論", systemImage: "text.book.closed")
                    .font(.headline)
                Text(instrument.descriptionFullZh)
                    .font(.body)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var studyGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("專業學習筆記")
                .font(.title3.weight(.bold))
            StudyNoteCard(title: "形制與發聲", icon: "waveform.path", text: guide.formAndSound, color: AppTheme.jade)
            StudyNoteCard(title: "樂團角色", icon: "music.note.house", text: guide.ensembleRole, color: AppTheme.cinnabar)
            StudyNoteCard(title: "排練檢核", icon: "checklist.checked", text: guide.rehearsalChecklist, color: AppTheme.lapis)
            StudyNoteCard(title: "保養與使用", icon: "wrench.and.screwdriver", text: guide.maintenance, color: AppTheme.gold)
            StudyNoteCard(title: "聽辨重點", icon: "ear", text: guide.listeningFocus, color: AppTheme.jade)
        }
    }

    private var facts: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("演奏資訊")
                    .font(.headline)
                    .padding(.bottom, 4)
                InfoRow(title: "聲部", value: section?.nameZh ?? instrument.sectionId)
                InfoRow(title: "音域", value: "\(instrument.rangeZh)（\(instrument.rangeNotation)）")
                InfoRow(title: "技法", value: instrument.playingTechniqueZh)
                InfoRow(title: "定弦／配置", value: instrument.tuningZh)
                InfoRow(title: "代表曲目", value: instrument.famousPiecesZh)
                InfoRow(title: "入門難度", value: instrument.beginnerDifficultyLabel)
                InfoRow(title: "進階特性", value: instrument.difficultyLevelAdvanced.zhDifficultyLabel)
            }
        }
    }

    private var sourceDisclosures: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("素材來源與授權")
                .font(.title3.weight(.bold))
            AudioSourceDisclosureCard(instrument: instrument)
            ArtworkReviewDisclosureCard(instrument: instrument)
        }
    }
}

private struct StudyNoteCard: View {
    let title: String
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        AppSurface {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 38, height: 38)
                    .background(color.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.headline)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct InstrumentStudyGuide {
    let formAndSound: String
    let ensembleRole: String
    let rehearsalChecklist: String
    let maintenance: String
    let listeningFocus: String
}

private enum InstrumentStudyCatalog {
    static func guide(for instrument: Instrument, section: OrchestraSection?) -> InstrumentStudyGuide {
        let profile = specificProfile(for: instrument.id)
        return InstrumentStudyGuide(
            formAndSound: profile.form,
            ensembleRole: profile.role,
            rehearsalChecklist: rehearsalText(for: instrument, sectionID: instrument.sectionId),
            maintenance: maintenanceText(for: instrument, sectionID: instrument.sectionId),
            listeningFocus: "聽辨時先記住「\(instrument.playingTechniqueZh)」對起音、持續音與收尾的影響，再對照\(instrument.famousPiecesZh)中的句法。試聽按鈕僅在已取得可商用授權的實器錄音存在時開放，未授權曲目不附音檔。"
        )
    }

    private static func specificProfile(for id: String) -> (form: String, role: String) {
        switch id {
        case "dizi":
            return ("竹製橫吹管身設吹孔、指孔與膜孔；氣流切過吹孔發聲，笛膜帶來可識別的粗粒與振動。曲笛、梆笛與新笛在管長、調性和聲音密度上不同。", "常擔任高音旋律、裝飾性對句與色彩性獨奏；合奏時需在明亮穿透與聲部融合之間取得平衡。")
        case "sheng":
            return ("簧片裝在多根簧管上，管根置於斗狀風箱；吹、吸均可發聲。傳統笙與鍵笙的簧數、指法和音域不同，實際編配要以樂譜標示為準。", "能提供持續和聲、和弦連接、琥69f0與旋律；是吹管聲部中少數可同時發多音的樂器。")
        case "suona":
            return ("雙簧連接圓錐形管身與金屬喇叭口，簧片、口勁與氣壓共同決定音準與音色。高、中、低音及不同調性形制不宜混為一種。", "負責高穿透的旋律、戲劇性強奏與民俗色彩；大編制中需特別管控動態，避免覆蓋其他木管與拉弦線條。")
        case "xiao":
            return ("簫為竹製直吹管樂器，氣流切過頂端吹口發聲；洞簫、琴簫等形制在管徑、指孔與音色上有別。它不使用笛膜，氣聲比例與吹口角度很關鍵。", "常用於弱奏長線條、獨奏引子、文人性色彩和空間氛圍；與笛同部時要刻意區分氣息質地。")
        case "guanzi":
            return ("管子以雙簧與近圓柱形管身發聲，大小、調性與指孔系統因地域和現代改良而異。調音常需同時控制簧片、口勁與氣壓。", "常呈現蒼勁、鼻音明顯的旋律和北方鼓吹樂色彩；在樂團中是性格強烈的中高音木管聲部。")
        case "pipa":
            return ("梨形共鳴箱、短頸品位與四弦構成主體；右手戴假甲做彈挑、輪指與掃拂，左手在品位間做吟揉、推拉與絞弦。", "可擔任獨奏、高中音旋律、快速音型與節奏強調；文曲與武曲所需觸弦、音頭和殘響控制明顯不同。")
        case "guzheng":
            return ("長箱形箏體上張弦，每弦經可移動琴碼分成發音段與按音段。右手主要觸弦，左手除觸弦外也透過按壓改變音高與音飾。", "能承擔獨奏、琥69f0音場、快速指序和色彩音型；合奏時要處理右手發音與左手滑音對和聲的影響。")
        case "yangqin":
            return ("梯形琴箱上的金屬弦經多組琴碼分區，用一對琴竹擊弦。同一條弦系在琴碼兩側可形成不同音高，視譜與走位需建立穩定的音位地圖。", "於彈撥聲部連結和聲、節奏和快速音群；也可以滾竹與延音擔任旋律，要避免顆粒過硬而破壞合奏層次。")
        case "liuqin":
            return ("小型梨形或柳葉形彈撥樂器，現代常見四弦、有品位，用撥片演奏。短弦長帶來快速反應與明亮音頭，音準仍受按弦力度影響。", "擔任彈撥組最高部的旋律、快速音階和光澤性裝飾；合奏時需管理銳利音頭與其他彈撥樂器的對齊。")
        case "zhongruan":
            return ("圓形共鳴箱、長頸品位與四弦構成中音彈撥聲部，常用撥片演奏。中阮、大阮等型制的定弦與功能不應混用。", "提供中音旋律、分解和弦、節奏底層與彈撥組厚度；是連結柳琴、琵琶亮度與低音支撐的關鍵中層。")
        case "sanxian":
            return ("長頸、無品指板、三弦與蒙皮共鳴箱構成；地域流派有大小三弦與不同定弦。無品設計讓滑音靈活，也要求更精確的左手音準。", "帶來顆粒清楚、語言性強的節奏與旋律，能連結說唱、戲曲及現代合奏語彙。")
        case "konghou":
            return ("現代箜篌是直立框架的雙排弦樂器，與古代文獻中多種箜篌形制並不相同。部分現代型藉雙排弦和壓弦機構產生滑音、琥69f0與和聲。", "常用於雙手琥69f0、寬廣和弦、透明色彩與獨奏段；編曲時應確認實際樂器的半音機構和滑音限制。")
        case "erhu":
            return ("兩弦經琴碼傳振至蒙皮琴筒，弓毛穿在內外弦之間；左手按弦無指板支撐。琴筒、琴皮、琴碼與千斤狀態會明顯改變發音。", "是拉弦組主要旋律核心，也常作獨奏；聲部排練要統一弓向、揉弦幅度、滑音時值與句尾收音。")
        case "gaohu":
            return ("高胡屬高音胡琴，琴筒與弦長通常較二胡小，定弦較高；廣東音樂傳統演奏法常將琴筒夾於兩膝間，不應只從外觀當作二胡。", "擔任高音拉弦旋律、廣東音樂裝飾語彙與明亮線條；需注意音準敏感度與穿透力。")
        case "zhonghu":
            return ("中胡是較大型、較低定弦的胡琴，形制上仍保留兩弦、弓毛穿弦與蒙皮共鳴筒等特徵。琴筒尺寸與琴碼配置影響中低音的反應。", "填補二胡與低音拉弦之間的中聲部，可奏內聲部和聲、副旋律與溫厚長音。")
        case "banhu":
            return ("板胡以木板為共鳴面，不同劇種的琴筒、弦長、定弦和弓法均有差異。亮而集中的音頭來自其結構與高張力發音，不能以二胡音色替代。", "在梆子腔及北方戲曲語彙中負責尖亮旋律、快弓與腔韻；現代樂團中常作鮮明色彩聲部。")
        case "gehu":
            return ("革胡是現代國樂團低音化過程中發展的四弦拉弦樂器，常採類似大提琴的立式演奏姿態與定弦邏輯。實際形制有差異，須以樂團現用樂器確認。", "負責低音旋律、和聲根音與長線條支撐；常與低音革胡或大提琴分工，編制需以譜面標示為準。")
        case "bianzhong":
            return ("編鐘由多枚青銅鐘按音高懸掛排列，某些合瓦形鐘體在正鼓部與側鼓部可發不同音高。複製古編鐘與現代舞台型的音列、音準和槌具配置不同。", "用於有音高的青銅色彩、禮樂象徵、和聲點染與獨奏段；作曲與排練前必須先確認現場鐘組的實際音列。")
        case "tanggu":
            return ("堂鼓是木製鼓腔、蒙皮的雙面鼓類，演奏面中心、邊緣與不同鼓棒會產生不同音頭與低頻量感。鼓皮張力、濕度和放置高度都會影響反應。", "擔任節奏核心、結構性重音、滾奏推進和戲劇高潮；音量平衡需以整團音場而非演奏者座位判斷。")
        case "luo":
            return ("鑼是懸掛或手持的金屬體鳴樂器，大鑼、小鑼、風鑼等在盤面、鑼臍、厚度與音高穩定性上不同。擊點、槌頭材質與悶音時機決定泛音發展。", "用一擊改變場面層次，也能滾奏建立色彩與張力；戲曲鑼鼓經中還承擔明確語法功能。")
        case "bo":
            return ("鈸由兩片金屬盤互擊發聲，大小、厚度、弧度與鑼臍形狀決定音頭和泛音。合擊後是否立即收音，會形成完全不同的節奏語法。", "強化結構重音、戲曲場面與高潮爆發力，也可用輕擊、摩擦與悶音做細節音色。")
        case "muyu":
            return ("木魚為挖空並開縫的木質體鳴樂器，不同尺寸形成相對高低。擊點、木槌硬度和持握方式會影響音頭的清晰度與殘響。", "提供短促、乾淨的節奏刻度，可突顯拍點、重複音型或宗教與民間色彩。")
        case "paigu":
            return ("排鼓由多面可調音的鼓組成，數量、排列、鼓皮與調音機構因製式而異。它的主要音高仍伴隨大量無固定音高的瞬態與泛音，不應當作鍵盤樂器般調音。", "結合節奏推進、輪鼓移動與旋律性輪廓，常擔任獨奏與高潮；位置規劃需同時考慮音高順序與肢體路徑。")
        default:
            return ("本樂器的形制、材料、發音法與調律系統共同決定音色，閱讀時應連結實物照片、實器錄音與演奏技法。", "樂團中的功能不只是音域，還包含起音、殘響、動態與句法在整體配器中的位置。")
        }
    }

    private static func rehearsalText(for instrument: Instrument, sectionID: String) -> String {
        let core: String
        switch sectionID {
        case "wind":
            core = "先以長音確認氣流、音準中心與音色，再對齊吐音、換氣點和裝飾音。"
        case "plucked":
            core = "先統一觸弦位置、音頭與殘響長度，再處理輪奏、掃弦與快速音型的聲部對齊。"
        case "bowed":
            core = "先統一弓速、弓壓、弓向和音準參照，再校對揉弦幅度、滑音時值與句尾。"
        default:
            core = "先確認槌具、擊點、收音方式與動態層級，再用指揮拍點校對聲部入口。"
        }
        return "\(core)本樂器主要技法為\(instrument.playingTechniqueZh)；排練前同時確認「\(instrument.tuningZh)」與樂譜實際要求。"
    }

    private static func maintenanceText(for instrument: Instrument, sectionID: String) -> String {
        switch sectionID {
        case "wind":
            return "演奏後移除管內水氣，保持吹口、簧片或笛膜區域穩定；不以高溫曝曬或劇烈乾燥加速竹、木材開裂。使用前要依\(instrument.tuningZh)確認實際型制。"
        case "plucked":
            return "練習後清除弦、品位與面板汗漬，定期檢查弦的磨損、琴碼位置與共鳴箱異響。携行時使用硬盒並避免琴碼受壓或溫濕度驟變。"
        case "bowed":
            return "演奏後擦除弦與琴筒上的松香、汗漬，收藏前放鬆弓毛；蒙皮、琴碼、千斤或指板系統皆不宜自行大幅調整。變形或異響應由熟悉該形制的技師處理。"
        default:
            return "演奏後清除鼓皮、金屬或木質表面的汗水，槌具與樂器分開固定。搬運前確認支架、懸掛與調音裝置；青銅、鼓皮或漆面不使用未經確認的清潔劑。"
        }
    }
}
