import SwiftUI

struct PremiumView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: OrchestraStore
    @EnvironmentObject private var premiumStore: PremiumStore
    private let proOutcomes = [
        ProOutcome(title: "樂器專項", detail: "23 種樂器各 50 題，含解析與重練。", systemImage: "list.number"),
        ProOutcome(title: "基礎知識", detail: "230 題涵蓋聲部、形制、發聲、音域與編制。", systemImage: "books.vertical"),
        ProOutcome(title: "實器聽辨", detail: "只納入已取得商用授權並可稽核來源的真實錄音。", systemImage: "ear.badge.waveform"),
        ProOutcome(title: "購買保障", detail: "非消耗性一次購買，支援同一 Apple ID 恢復。", systemImage: "arrow.clockwise.circle")
    ]
    private let proServices = [
        ProService(title: "樂器完整題庫", detail: "每種樂器免費 5 題；Pro 解鎖同一套作答流程的完整 50 題。", systemImage: "music.note.list"),
        ProService(title: "基礎完整題庫", detail: "免費 20 題；Pro 解鎖 230 題，作答後可查看解析並重練。", systemImage: "checklist.checked"),
        ProService(title: "實器聽辨完整題庫", detail: "免費 5 題；Pro 解鎖目前所有已核准音源題，未核准樂器不會以假音色補位。", systemImage: "ear"),
        ProService(title: "購買與恢復", detail: "由 Apple StoreKit 處理一次性購買；App 內提供恢復購買按鈕。", systemImage: "creditcard")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if isPaymentScreenshotMode {
                        purchasePanel
                        assetCreditsLink
                        trialComparisonPanel
                        paymentReviewPanel
                        professionalServicesPanel
                        professionalValuePanel
                        valueStack
                    } else {
                        hero
                        assetCreditsLink
                        trialComparisonPanel
                        professionalServicesPanel
                        professionalValuePanel
                        valueStack
                        purchasePanel
                        paymentReviewPanel
                    }
                    reviewSafeNote
                }
                .padding(16)
                .padding(.bottom, 96)
            }
            .background(AppTheme.background)
            .navigationTitle("國樂團練習室 Pro")
        }
        .task {
            await premiumStore.loadProducts()
        }
    }

    private var isPaymentScreenshotMode: Bool {
        ProcessInfo.processInfo.environment["GYZP_SCREENSHOT_TAB"] == "payment"
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
        .accessibilityLabel("國樂團練習室 Pro，先試用，一次解鎖")
    }

    private var compactWidthHero: some View {
        ZStack(alignment: .bottomLeading) {
            BrandHeroImage(height: 245)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                PremiumPill(text: premiumStore.isProUnlocked ? "Pro 已啟用" : "先試用 · 一次解鎖")
                Text("把圖鑑變成真正的國樂練功房")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("適合自學、導聆與帶團前複習。Pro 解鎖樂器、基礎知識與已核准實器聽辨的完整題庫。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
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

                VStack(alignment: .leading, spacing: 14) {
                    PremiumPill(text: premiumStore.isProUnlocked ? "Pro 已啟用" : "先試用 · 一次解鎖")
                    Text("把圖鑑變成真正的國樂練功房")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("適合自學、導聆與帶團前複習。Pro 解鎖樂器、基礎知識與已核准實器聽辨的完整題庫。")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.80))
                        .fixedSize(horizontal: false, vertical: true)
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

    private var trialComparisonPanel: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 14) {
                Label("免費可用，Pro 解鎖完整量", systemImage: "rectangle.split.2x1")
                    .font(.headline)

                Text("先做完一段真正的練習，再決定是否購買。每種模式都保留可重複作答的免費內容。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    PracticeAccessRow(title: "每種樂器", free: "5 題", pro: "50 題")
                    Divider()
                    PracticeAccessRow(title: "基礎知識", free: "20 題", pro: "\(store.instruments.count * 10) 題")
                    Divider()
                    PracticeAccessRow(title: "實器聽辨", free: "5 題", pro: "\(AudioSourceCatalog.approvedSources.count * 3) 題")
                    Divider()
                    PracticeAccessRow(title: "圖鑑與來源", free: "全部", pro: "全部")
                }
                .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("若實拍或錄音尚未取得授權，免費與 Pro 都不會顯示假素材。")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.cinnabar)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var professionalValuePanel: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 14) {
                Label("可直接核對的 Pro 內容", systemImage: "checkmark.seal")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(proOutcomes) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: item.systemImage)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.cinnabar)
                            Text(item.title)
                                .font(.subheadline.weight(.bold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
                        .padding(12)
                        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var professionalServicesPanel: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 14) {
                Label("Pro 實際解鎖內容", systemImage: "lock.open")
                    .font(.headline)

                Text("以下都是 App 內可實際作答、查看解析並重複練習的內容。音檔仍以授權與專業審核 gate 為準，不把候選或舊版合成素材包裝成正式內容。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(proServices) { service in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: service.systemImage)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.cinnabar)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.title)
                                    .font(.subheadline.weight(.bold))
                                Text(service.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var valueStack: some View {
        VStack(spacing: 12) {
            ForEach(PremiumFeature.allCases) { feature in
                PremiumTeaserCard(feature: feature, isUnlocked: premiumStore.isProUnlocked)
            }
        }
    }

    private var purchasePanel: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(premiumStore.isProUnlocked ? "Pro 已啟用" : premiumStore.proProductTitle)
                            .font(.title3.weight(.bold))
                        Text(premiumStore.proPriceText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.cinnabar)
                    }

                    Spacer()

                    Image(systemName: premiumStore.isProUnlocked ? "checkmark.seal.fill" : "lock.open")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(premiumStore.isProUnlocked ? AppTheme.jade : AppTheme.gold)
                }

                StoreStatusRow(
                    text: premiumStore.productAvailabilityText,
                    isReady: premiumStore.isProUnlocked || premiumStore.isProProductLoaded
                )

                if let status = premiumStore.statusMessage {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("商品 ID：\(PremiumStore.proProductID)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if premiumStore.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("正在連線 App Store")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    Task { await premiumStore.purchasePro() }
                } label: {
                    Label(premiumStore.isProUnlocked ? "已解鎖" : "一次購買解鎖 Pro", systemImage: premiumStore.isProUnlocked ? "checkmark" : "creditcard")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cinnabar)
                .disabled(premiumStore.isLoading || premiumStore.isProUnlocked)

                Button {
                    Task { await premiumStore.restorePurchases() }
                } label: {
                    Label("恢復購買", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(premiumStore.isLoading)

                if !premiumStore.isProProductLoaded && !premiumStore.isProUnlocked {
                    Button {
                        Task { await premiumStore.loadProducts() }
                    } label: {
                        Label("重新載入 App Store 商品", systemImage: "icloud.and.arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(premiumStore.isLoading)
                }
            }
        }
    }

    private var paymentReviewPanel: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 12) {
                Label("Apple StoreKit 付款頁面", systemImage: "creditcard")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    paymentRow("解鎖內容", "23 種樂器各 50 題、230 題基礎知識與已授權實器聽辨")
                    paymentRow("付款方式", "一次性 App 內購買，由 App Store 安全處理")
                    paymentRow("恢復購買", "更換裝置或重新安裝後，可用同一 Apple ID 恢復")
                    paymentRow("素材承諾", "不以 AI 或電子波形冒充國樂實器聲音")
                    paymentRow("隱私", "不建立帳號、不追蹤、不收集付款資料")
                }
            }
        }
    }

    private func paymentRow(_ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.jade)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var reviewSafeNote: some View {
        Text("所有已內建內容皆可離線使用；購買流程使用 Apple StoreKit，無第三方帳號登入、無追蹤、無廣告。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private var assetCreditsLink: some View {
        NavigationLink {
            AssetCreditsView()
        } label: {
            Label("查看實拍、音源來源與授權", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct PracticeAccessRow: View {
    let title: String
    let free: String
    let pro: String

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("免費 \(free)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Pro \(pro)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.cinnabar)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
    }
}

private struct ProOutcome: Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let systemImage: String
}

private struct ProService: Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let systemImage: String
}

private struct StoreStatusRow: View {
    let text: String
    let isReady: Bool

    var body: some View {
        Label {
            Text(text)
                .font(.footnote.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isReady ? AppTheme.jade : AppTheme.gold)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isReady ? AppTheme.jade : AppTheme.gold).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
