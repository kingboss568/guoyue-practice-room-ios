import SwiftUI

struct AssetCreditsView: View {
    var body: some View {
        List {
            Section {
                Text("圖片只採用可追溯的真實樂器實拍；App 內試聽只播放已確認來源、商用授權、雜湊與格式的實器錄音。尚未取得再散布權的項目只開啟原站真人示範，不複製影音、不進入聽辨題庫，也不以 AI 圖、相似樂器或合成音替代。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("已核准實器音檔") {
                ForEach(AudioSourceCatalog.approvedSources) { source in
                    AudioSourceCreditRow(source: source)
                }
            }

            if !AudioSourceCatalog.candidateSources.isEmpty {
                Section("候選來源，尚未包入") {
                    ForEach(AudioSourceCatalog.candidateSources) { source in
                        AudioSourceCreditRow(source: source)
                    }
                }
            }

            Section("原站實器示範（未包入 App）") {
                ForEach(ExternalInstrumentDemonstrationCatalog.references) { reference in
                    ExternalInstrumentDemonstrationRow(reference: reference)
                }
            }

            Section("已核對樂器實拍") {
                ForEach(PhotoSourceCatalog.verifiedSources) { source in
                    PhotoSourceCreditRow(source: source)
                }
            }

            Section("實拍授權待補") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("排鼓：尚未取得可商用整組實拍，App 不以單鼓替代。", systemImage: "photo.badge.exclamationmark")
                    Link(
                        "查看香港音樂事務處的五件式排鼓實拍與示範",
                        destination: URL(string: "https://www.lcsd.gov.hk/en/mo/musicguide/en/chinese_musical.html")!
                    )
                    .font(.footnote.weight(.semibold))
                }
            }
        }
        .navigationTitle("素材來源")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AudioSourceDisclosureCard: View {
    let instrument: Instrument

    private var source: AudioSourceCredit? {
        AudioSourceCatalog.source(for: instrument)
    }

    private var externalDemonstration: ExternalInstrumentDemonstration? {
        ExternalInstrumentDemonstrationCatalog.reference(for: instrument)
    }

    var body: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    "音源狀態",
                    systemImage: source?.isPlayable == true
                        ? "checkmark.seal"
                        : (externalDemonstration == nil ? "exclamationmark.triangle" : "link")
                )
                    .font(.headline)

                if let source {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(source.status.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(source.isPlayable ? AppTheme.jade : AppTheme.gold)
                            Spacer()
                            Text(source.license)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(source.sourceTitle)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("作者：\(source.author)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(source.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let sha256 = source.sha256 {
                            Text("SHA-256：\(sha256)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                        }

                        if let sourceURL = source.sourceURL {
                            Link("開啟音源來源頁", destination: sourceURL)
                                .font(.footnote.weight(.semibold))
                        }
                    }
                } else if let externalDemonstration {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原站實器示範（未包入 App）")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.lapis)

                        Text(externalDemonstration.sourceTitle)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("提供者：\(externalDemonstration.provider)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(externalDemonstration.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Link("開啟原站實器示範", destination: externalDemonstration.sourceURL)
                            .font(.footnote.weight(.semibold))
                    }
                } else {
                    Text("此樂器尚未取得可商用且可稽核的實器錄音；App 暫停播放舊版合成音檔，避免誤導專業使用者。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct ExternalInstrumentDemonstrationRow: View {
    let reference: ExternalInstrumentDemonstration

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(reference.instrumentName) \(reference.instrumentID)")
                .font(.headline)
            Text(reference.sourceTitle)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Text("提供者：\(reference.provider)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(reference.note)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Link("開啟原站", destination: reference.sourceURL)
                .font(.footnote.weight(.semibold))
        }
        .padding(.vertical, 6)
    }
}

struct ArtworkReviewDisclosureCard: View {
    let instrument: Instrument

    private var record: ArtworkReviewRecord? {
        ArtworkReviewCatalog.record(for: instrument)
    }

    private var source: PhotoSourceCredit? {
        PhotoSourceCatalog.source(for: instrument)
    }

    var body: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                Label("圖片校對狀態", systemImage: record?.status.isApproved == true ? "checkmark.seal" : "paintbrush.pointed")
                    .font(.headline)

                if let record, let source {
                    HStack(alignment: .firstTextBaseline) {
                        Text(record.status.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(record.status.isApproved ? AppTheme.jade : AppTheme.cinnabar)
                        Spacer()
                        Text(record.risk.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(source.sourceTitle)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("作者：\(source.author) · \(source.license)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(record.requiredChecks, id: \.self) { check in
                            Label(check, systemImage: "checklist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let sourceURL = source.sourceURL {
                        Link("開啟圖片來源頁", destination: sourceURL)
                            .font(.footnote.weight(.semibold))
                    }
                } else if let record {
                    Text(record.status.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.cinnabar)
                    Text("此頁不顯示舊版生成圖；只在取得精確樂器的可商用實拍與授權記錄後才開放。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(record.requiredChecks, id: \.self) { check in
                        Label(check, systemImage: "checklist")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("此樂器尚未建立圖片校對紀錄；不得視為可送審素材。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PhotoSourceCreditRow: View {
    let source: PhotoSourceCredit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(source.instrumentName) \(source.instrumentID)")
                    .font(.headline)
                Spacer()
                Text(source.license)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.jade)
            }
            Text(source.sourceTitle)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Text("作者：\(source.author)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let sourceURL = source.sourceURL {
                Link("開啟圖片來源頁", destination: sourceURL)
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(.vertical, 6)
    }
}

private struct AudioSourceCreditRow: View {
    let source: AudioSourceCredit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(source.instrumentName) \(source.instrumentID)")
                    .font(.headline)
                Spacer()
                Text(source.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(source.isPlayable ? AppTheme.jade : AppTheme.gold)
            }

            Text(source.sourceTitle)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Text("作者：\(source.author)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(source.license)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            Text(source.note)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let sourceURL = source.sourceURL {
                Link("開啟來源頁", destination: sourceURL)
                    .font(.footnote.weight(.semibold))
            }

            if let sha256 = source.sha256 {
                Text("SHA-256：\(sha256)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .padding(.vertical, 6)
    }
}
