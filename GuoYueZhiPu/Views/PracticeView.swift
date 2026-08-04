import SwiftUI

struct PracticeView: View {
    @State private var mode: PracticeMode = .instruments

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
                case .instruments:
                    InstrumentPracticeCatalogView()
                case .foundations:
                    FoundationPracticeView()
                case .listening:
                    ListeningPracticeView()
                case .lessons:
                    LessonsView()
                }
            }
            .background(AppTheme.background)
            .navigationTitle("練功房")
        }
    }
}

private enum PracticeMode: String, CaseIterable, Identifiable {
    case instruments
    case foundations
    case listening
    case lessons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instruments: return "樂器"
        case .foundations: return "基礎"
        case .listening: return "聽辨"
        case .lessons: return "課程"
        }
    }
}

private struct InstrumentPracticeCatalogView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PracticeModeHeader(
                    title: "23 種樂器專項題庫",
                    detail: "每種樂器 50 題，涵蓋中英名稱、聲部、形制、音域、定弦、技法與代表曲目。",
                    count: "1,150 題",
                    trial: premiumStore.isProUnlocked ? "已全數解鎖" : "每種免費 5 題",
                    icon: "music.note.list"
                )

                ForEach(store.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionBadge(section: section)
                            Text(section.blurbZh)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        ForEach(store.instruments(in: section.id)) { instrument in
                            NavigationLink {
                                InstrumentPracticeOverview(instrument: instrument)
                            } label: {
                                InstrumentPracticeRow(
                                    instrument: instrument,
                                    isUnlocked: premiumStore.isProUnlocked
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                PracticeUpgradeCard()
            }
            .padding(16)
            .padding(.bottom, 92)
        }
        .background(AppTheme.background)
    }
}

private struct InstrumentPracticeRow: View {
    let instrument: Instrument
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 13) {
            InstrumentArtwork(instrument: instrument, cornerRadius: 12)
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(instrument.nameZh)
                        .font(.headline)
                    Text(instrument.nameEn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text("音域、定弦、技法、名曲與聲部判讀")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(isUnlocked ? "50 / 50 題可練" : "免費 5 題 · Pro 50 題")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isUnlocked ? AppTheme.jade : AppTheme.cinnabar)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct InstrumentPracticeOverview: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore
    let instrument: Instrument

    private var allQuestions: [PracticeQuestion] {
        PracticeQuestionBank.instrumentQuestions(
            for: instrument,
            allInstruments: store.instruments,
            sections: store.sections,
            idPrefix: "instrument"
        )
    }

    private var availableQuestions: [PracticeQuestion] {
        premiumStore.isProUnlocked ? allQuestions : Array(allQuestions.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZStack(alignment: .bottomLeading) {
                    InstrumentArtwork(instrument: instrument, cornerRadius: 22)
                        .frame(height: 230)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(instrument.nameZh) 專項練功")
                            .font(.title.weight(.black))
                            .foregroundStyle(.white)
                        Text("完整題庫 50 題")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.90))
                    }
                    .padding(18)
                }

                AppSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("本次練習", systemImage: "target")
                            .font(.headline)
                        Text(premiumStore.isProUnlocked ? "Pro 已解鎖，本次可作答全部 50 題。" : "免費版可完整作答前 5 題；作答、解析與重練都可實際使用。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            TagLabel(text: "\(availableQuestions.count) 題", color: AppTheme.cinnabar)
                            TagLabel(text: instrument.rangeNotation, color: AppTheme.lapis)
                            TagLabel(text: instrument.beginnerDifficultyLabel, color: AppTheme.jade)
                        }
                    }
                }

                NavigationLink {
                    PracticeQuestionSessionView(
                        title: "\(instrument.nameZh) 題庫",
                        questions: availableQuestions,
                        fullQuestionCount: allQuestions.count
                    )
                } label: {
                    Label("開始 \(availableQuestions.count) 題練習", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cinnabar)

                if !premiumStore.isProUnlocked { PracticeUpgradeCard() }
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .navigationTitle(instrument.nameZh)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FoundationPracticeView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore

    private var allQuestions: [PracticeQuestion] {
        PracticeQuestionBank.foundationQuestions(instruments: store.instruments, sections: store.sections)
    }

    private var availableQuestions: [PracticeQuestion] {
        premiumStore.isProUnlocked ? allQuestions : Array(allQuestions.prefix(20))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PracticeModeHeader(
                    title: "國樂基礎知識",
                    detail: "以 23 件樂器的可驗證資料各取 10 個知識點，組成聲部、名稱、音域、技法、定弦與曲目題庫。",
                    count: "\(allQuestions.count) 題",
                    trial: premiumStore.isProUnlocked ? "已全數解鎖" : "免費 20 題",
                    icon: "books.vertical.fill"
                )

                AppSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("題庫結構")
                            .font(.headline)
                        PracticeCoverageRow(icon: "rectangle.3.group", title: "聲部與編制", detail: "吹管、彈撥、拉弦、打擊")
                        PracticeCoverageRow(icon: "waveform.path", title: "音域與定弦", detail: "依 App 樂器資料逐項出題")
                        PracticeCoverageRow(icon: "hand.point.up.braille", title: "演奏技法", detail: "辨識技法與正確樂器的對應")
                        PracticeCoverageRow(icon: "music.note", title: "代表曲目", detail: "只作知識題，未授權作品不播放音檔")
                    }
                }

                NavigationLink {
                    PracticeQuestionSessionView(
                        title: "國樂基礎",
                        questions: availableQuestions,
                        fullQuestionCount: allQuestions.count
                    )
                } label: {
                    Label("開始 \(availableQuestions.count) 題基礎測驗", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.jade)

                if !premiumStore.isProUnlocked { PracticeUpgradeCard() }
            }
            .padding(16)
            .padding(.bottom, 92)
        }
        .background(AppTheme.background)
    }
}

private struct ListeningPracticeView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore

    private var allQuestions: [PracticeQuestion] {
        PracticeQuestionBank.listeningQuestions(instruments: store.instruments)
    }

    private var availableQuestions: [PracticeQuestion] {
        premiumStore.isProUnlocked ? allQuestions : Array(allQuestions.prefix(5))
    }

    private var missingNames: String {
        store.instruments
            .filter { AudioSourceCatalog.approvedSource(for: $0) == nil }
            .map(\.nameZh)
            .joined(separator: "、")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PracticeModeHeader(
                    title: "實器音色聽辨",
                    detail: "每題都先播放可追溯授權的真實樂器片段，再作樂器辨識；絕不用正弦波、MIDI 或相似樂器代替。",
                    count: "\(allQuestions.count) 題 · \(AudioSourceCatalog.approvedSources.count) 種實器",
                    trial: premiumStore.isProUnlocked ? "已全數解鎖" : "免費 5 題",
                    icon: "ear.badge.waveform"
                )

                AppSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("專業素材底線", systemImage: "checkmark.shield")
                            .font(.headline)
                        Text("現已納入 \(AudioSourceCatalog.approvedSources.count) 種可稽核實器錄音。每份來源、作者、授權與 SHA-256 均在素材來源頁揭露。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("尚未開放：\(missingNames)。這些樂器尚未取得可商業再散布的隔離實器音檔，因此不進入聽辨題；可從各樂器頁開啟原站真人示範。")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.cinnabar)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                NavigationLink {
                    PracticeQuestionSessionView(
                        title: "實器聽辨",
                        questions: availableQuestions,
                        fullQuestionCount: allQuestions.count
                    )
                } label: {
                    Label("開始 \(availableQuestions.count) 題聽辨", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cinnabar)
                .disabled(availableQuestions.isEmpty)

                NavigationLink {
                    AssetCreditsView()
                } label: {
                    Label("檢查每一份錄音來源", systemImage: "doc.text.magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                if !premiumStore.isProUnlocked { PracticeUpgradeCard() }
            }
            .padding(16)
            .padding(.bottom, 92)
        }
        .background(AppTheme.background)
    }
}

private struct PracticeModeHeader: View {
    let title: String
    let detail: String
    let count: String
    let trial: String
    let icon: String

    var body: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.cinnabar)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.cinnabar.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.title3.weight(.bold))
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 8) {
                    TagLabel(text: count, color: AppTheme.lapis)
                    TagLabel(text: trial, color: AppTheme.jade)
                }
            }
        }
    }
}

private struct PracticeCoverageRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.cinnabar)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

private struct PracticeUpgradeCard: View {
    @EnvironmentObject private var premiumStore: PremiumStore

    var body: some View {
        if !premiumStore.isProUnlocked {
            NavigationLink {
                PremiumView()
            } label: {
                AppSurface {
                    HStack(spacing: 13) {
                        Image(systemName: "sparkles")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.gold)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("先試用，需要再解鎖")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("每種樂器、基礎測驗與真實聽辨都有免費可作答內容；Pro 一次解鎖完整題庫。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct PracticeQuestionSessionView: View {
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @StateObject private var tonePlayer = TonePlayer()
    @State private var currentIndex = 0
    @State private var selectedIndex: Int?
    @State private var score = 0
    @State private var isFinished = false

    let title: String
    let questions: [PracticeQuestion]
    let fullQuestionCount: Int

    private var question: PracticeQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var body: some View {
        Group {
            if questions.isEmpty {
                EmptyStateView(title: "尚無可用題目", message: "此模式需先完成資料與授權檢核。", systemImage: "questionmark.circle")
            } else if isFinished {
                resultView
            } else if let question {
                questionView(question)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { tonePlayer.stop() }
    }

    private func questionView(_ question: PracticeQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("第 \(currentIndex + 1) 題")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(currentIndex + 1) / \(questions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                        .tint(AppTheme.jade)
                }

                if let audioInstrumentID = question.audioInstrumentID,
                   let instrument = store.instruments.first(where: { $0.id == audioInstrumentID }) {
                    AppSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("真實樂器片段", systemImage: "waveform")
                                    .font(.headline)
                                Spacer()
                                Text(AudioSourceCatalog.approvedSource(for: instrument)?.license ?? "")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Button {
                                tonePlayer.activeInstrumentID == instrument.id ? tonePlayer.stop() : tonePlayer.play(instrument: instrument)
                            } label: {
                                Label(tonePlayer.activeInstrumentID == instrument.id ? "停止" : "播放實器錄音", systemImage: tonePlayer.activeInstrumentID == instrument.id ? "stop.fill" : "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.cinnabar)
                            Text("可重複播放後再作答；來源、作者與授權可在素材來源頁稽核。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                AppSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        TagLabel(text: question.category, color: AppTheme.cinnabar)
                        Text(question.prompt)
                            .font(.title2.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(question.options.indices, id: \.self) { index in
                        answerButton(question: question, index: index)
                    }
                }

                if let selectedIndex {
                    explanation(question: question, selectedIndex: selectedIndex)
                }
            }
            .padding(16)
        }
    }

    private func answerButton(question: PracticeQuestion, index: Int) -> some View {
        let isCorrect = question.correctIndex == index
        let isSelected = selectedIndex == index
        let shouldReveal = selectedIndex != nil
        let color: Color = shouldReveal && isCorrect ? AppTheme.jade : (isSelected ? AppTheme.cinnabar : Color(.separator))

        return Button {
            guard selectedIndex == nil else { return }
            selectedIndex = index
            if isCorrect { score += 1 }
        } label: {
            HStack(spacing: 12) {
                Text(question.options[index])
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if shouldReveal && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.jade)
                } else if isSelected {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.cinnabar)
                }
            }
            .padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(color, lineWidth: shouldReveal || isSelected ? 1.5 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(selectedIndex != nil)
    }

    private func explanation(question: PracticeQuestion, selectedIndex: Int) -> some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 13) {
                Label(selectedIndex == question.correctIndex ? "答對了" : "解析", systemImage: selectedIndex == question.correctIndex ? "checkmark.seal" : "lightbulb")
                    .font(.headline)
                    .foregroundStyle(selectedIndex == question.correctIndex ? AppTheme.jade : AppTheme.cinnabar)
                Text(question.explanation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    tonePlayer.stop()
                    if currentIndex == questions.count - 1 {
                        isFinished = true
                    } else {
                        currentIndex += 1
                        self.selectedIndex = nil
                    }
                } label: {
                    Label(currentIndex == questions.count - 1 ? "看結果" : "下一題", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.jade)
            }
        }
    }

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "seal.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(AppTheme.gold)
                Text("完成練習")
                    .font(.largeTitle.weight(.bold))
                Text("\(score) / \(questions.count)")
                    .font(.title.weight(.black))
                    .foregroundStyle(AppTheme.jade)
                Text(score == questions.count ? "全部正確，可重練巩固反應。" : "可重新作答，並回到樂器頁對照形制、技法與音源。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if questions.count < fullQuestionCount && !premiumStore.isProUnlocked {
                    Text("你已完成免費試用 \(questions.count) 題；完整題庫共 \(fullQuestionCount) 題。")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.cinnabar)
                        .multilineTextAlignment(.center)
                    PracticeUpgradeCard()
                }

                Button {
                    currentIndex = 0
                    selectedIndex = nil
                    score = 0
                    isFinished = false
                } label: {
                    Label("重新練習", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cinnabar)
            }
            .padding(24)
        }
    }
}

struct PracticeQuestion: Identifiable, Hashable {
    let id: String
    let category: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let audioInstrumentID: String?
}

enum PracticeQuestionBank {
    static func instrumentQuestions(
        for instrument: Instrument,
        allInstruments: [Instrument],
        sections: [OrchestraSection],
        idPrefix: String
    ) -> [PracticeQuestion] {
        let otherInstruments = prioritizedDistractors(for: instrument, allInstruments: allInstruments)
        let otherNames = otherInstruments.map(\.nameZh)
        let otherEnglishNames = otherInstruments.map(\.nameEn)
        let otherDescriptions = otherInstruments.map(\.descriptionBriefZh)
        let section = sections.first { $0.id == instrument.sectionId }
        let sectionName = section?.nameZh ?? instrument.sectionId
        let sectionNames = sections.map(\.nameZh)
        var result: [PracticeQuestion] = []

        for round in 0..<5 {
            for template in 0..<10 {
                let seed = round * 10 + template
                let id = "\(idPrefix)-\(instrument.id)-\(seed + 1)"
                let wording = wordingVariant(round)

                switch template {
                case 0:
                    result.append(makeQuestion(id: id, category: "中英名稱", prompt: "\(wording)「\(instrument.nameEn)」的中文樂器名稱是？", correct: instrument.nameZh, distractors: otherNames, explanation: "\(instrument.nameZh) 的英文名稱是 \(instrument.nameEn)。", seed: seed))
                case 1:
                    result.append(makeQuestion(id: id, category: "中英名稱", prompt: "\(wording)樂器「\(instrument.nameZh)」的英文名稱是？", correct: instrument.nameEn, distractors: otherEnglishNames, explanation: "\(instrument.nameZh) 對應 \(instrument.nameEn)。", seed: seed))
                case 2:
                    result.append(makeQuestion(id: id, category: "形制辨識", prompt: "\(wording)哪一件樂器符合這段描述：\(instrument.descriptionBriefZh)", correct: instrument.nameZh, distractors: otherNames, explanation: "這是 \(instrument.nameZh) 的形制與聲音摘要。", seed: seed))
                case 3:
                    result.append(makeQuestion(id: id, category: "演奏技法", prompt: "\(wording)「\(instrument.playingTechniqueZh)」是哪件樂器在本圖鑑中列出的主要技法？", correct: instrument.nameZh, distractors: otherNames, explanation: "\(instrument.nameZh) 的主要技法包含 \(instrument.playingTechniqueZh)。", seed: seed))
                case 4:
                    result.append(makeQuestion(id: id, category: "定弦與配置", prompt: "\(wording)「\(instrument.tuningZh)」對應哪件樂器？", correct: instrument.nameZh, distractors: otherNames, explanation: "\(instrument.nameZh) 的定弦或編制配置記錄為：\(instrument.tuningZh)。", seed: seed))
                case 5:
                    result.append(makeQuestion(id: id, category: "代表曲目", prompt: "\(wording)「\(instrument.famousPiecesZh)」在本圖鑑中列為哪件樂器的代表曲目？", correct: instrument.nameZh, distractors: otherNames, explanation: "本圖鑑將 \(instrument.famousPiecesZh) 列為 \(instrument.nameZh) 的代表聽辨脈絡。題目不附未授權作品音檔。", seed: seed))
                case 6:
                    result.append(makeQuestion(id: id, category: "音域", prompt: "\(wording)音域記錄為「\(instrument.rangeZh)（\(instrument.rangeNotation)）」的樂器是？", correct: instrument.nameZh, distractors: otherNames, explanation: "\(instrument.nameZh) 的圖鑑音域是 \(instrument.rangeZh)（\(instrument.rangeNotation)）。實際音域會因形制與演奏者而有差異。", seed: seed))
                case 7:
                    result.append(makeQuestion(id: id, category: "四大聲部", prompt: "\(wording)\(instrument.nameZh) 在本 App 的國樂團編制中屬於哪一聲部？", correct: sectionName, distractors: sectionNames.filter { $0 != sectionName }, explanation: "\(instrument.nameZh) 被分在\(sectionName)聲部。", seed: seed))
                case 8:
                    result.append(makeQuestion(id: id, category: "樂器描述", prompt: "\(wording)哪一段描述屬於「\(instrument.nameZh)」？", correct: instrument.descriptionBriefZh, distractors: otherDescriptions, explanation: "\(instrument.descriptionBriefZh)", seed: seed))
                default:
                    result.append(makeQuestion(id: id, category: "綜合判讀", prompt: "\(wording)哪件樂器同時符合「\(sectionName)聲部」、「\(instrument.rangeNotation)」與「\(instrument.beginnerDifficultyLabel)」這三項資料？", correct: instrument.nameZh, distractors: otherNames, explanation: "\(instrument.nameZh) 在資料中屬於\(sectionName)，音域標示 \(instrument.rangeNotation)，入門難度為\(instrument.beginnerDifficultyLabel)。", seed: seed))
                }
            }
        }
        return result
    }

    static func foundationQuestions(instruments: [Instrument], sections: [OrchestraSection]) -> [PracticeQuestion] {
        instruments.flatMap { instrument in
            Array(instrumentQuestions(for: instrument, allInstruments: instruments, sections: sections, idPrefix: "foundation").prefix(10))
        }
    }

    static func listeningQuestions(instruments: [Instrument]) -> [PracticeQuestion] {
        let approved = instruments.filter { AudioSourceCatalog.approvedSource(for: $0) != nil }
        var result: [PracticeQuestion] = []

        for (instrumentIndex, instrument) in approved.enumerated() {
            let distractors = prioritizedDistractors(for: instrument, allInstruments: approved).map(\.nameZh)
            guard let source = AudioSourceCatalog.approvedSource(for: instrument) else { continue }
            let prompts = [
                "播放片段後，辨識這件真實樂器。",
                "重複聽起音、持續音與收尾，這是哪件樂器？",
                "只依實器音色作答：錄音中的樂器是？"
            ]
            for round in 0..<3 {
                result.append(makeQuestion(
                    id: "listening-\(instrument.id)-\(round + 1)",
                    category: "實器聽辨",
                    prompt: prompts[round],
                    correct: instrument.nameZh,
                    distractors: distractors,
                    explanation: "此片段是 \(instrument.nameZh) 實器錄音。來源「\(source.sourceTitle)」，作者 \(source.author)，授權 \(source.license)；來源標示、商用授權、檔案雜湊與 App 音訊格式均已核對。",
                    seed: instrumentIndex * 3 + round,
                    audioInstrumentID: instrument.id
                ))
            }
        }
        return result
    }

    private static func prioritizedDistractors(for instrument: Instrument, allInstruments: [Instrument]) -> [Instrument] {
        let sameSection = allInstruments.filter { $0.id != instrument.id && $0.sectionId == instrument.sectionId }
        let otherSections = allInstruments.filter { $0.id != instrument.id && $0.sectionId != instrument.sectionId }
        return sameSection + otherSections
    }

    private static func wordingVariant(_ round: Int) -> String {
        ["基礎辨識：", "排練前複習：", "圖鑑對照：", "專項測驗：", "快速回想："][round % 5]
    }

    private static func makeQuestion(
        id: String,
        category: String,
        prompt: String,
        correct: String,
        distractors: [String],
        explanation: String,
        seed: Int,
        audioInstrumentID: String? = nil
    ) -> PracticeQuestion {
        var unique: [String] = [correct]
        for distractor in distractors where !unique.contains(distractor) {
            unique.append(distractor)
            if unique.count == 4 { break }
        }
        while unique.count < 4 {
            unique.append("不適用選項 \(unique.count)")
        }

        let rotation = seed % unique.count
        let options = Array(unique[rotation...]) + Array(unique[..<rotation])
        let correctIndex = options.firstIndex(of: correct) ?? 0
        return PracticeQuestion(
            id: id,
            category: category,
            prompt: prompt,
            options: options,
            correctIndex: correctIndex,
            explanation: explanation,
            audioInstrumentID: audioInstrumentID
        )
    }
}
