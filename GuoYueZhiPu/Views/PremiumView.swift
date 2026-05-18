import SwiftUI

struct PremiumView: View {
    @EnvironmentObject private var premiumStore: PremiumStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    valueStack
                    purchasePanel
                    reviewSafeNote
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle("國樂團練習室 Pro")
        }
        .task {
            await premiumStore.loadProducts()
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            BrandHeroImage(height: 245)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                PremiumPill(text: premiumStore.isProUnlocked ? "已解鎖" : "一次解鎖")
                Text("把圖鑑變成真正的國樂練功房")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("適合自學、導聆、考級與帶團前備課。免費版能入門，Pro 版補上深度聽辨、練習路線與完整聲音包。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
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
                        Text(premiumStore.isProUnlocked ? "Pro 已啟用" : "國樂團練習室 Pro")
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

                if let status = premiumStore.statusMessage {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task { await premiumStore.purchasePro() }
                } label: {
                    Label(premiumStore.isProUnlocked ? "已解鎖" : "解鎖 Pro", systemImage: premiumStore.isProUnlocked ? "checkmark" : "sparkles")
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
                    Text("恢復購買")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(premiumStore.isLoading)
            }
        }
    }

    private var reviewSafeNote: some View {
        Text("所有內容皆可離線使用；購買流程使用 Apple StoreKit，無第三方帳號登入、無追蹤、無廣告。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}
