import Foundation
import StoreKit

@MainActor
final class PremiumStore: ObservableObject {
    static let proProductID = "com.yuhsiangjiang.GuoYueZhiPu.pro"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var statusMessage: String?

    private var updatesTask: Task<Void, Never>?

    var isProUnlocked: Bool {
        purchasedProductIDs.contains(Self.proProductID)
    }

    var proPriceText: String {
        products.first(where: { $0.id == Self.proProductID })?.displayPrice ?? "App Store 商品設定後顯示"
    }

    init() {
        updatesTask = listenForTransactions()
        Task {
            await refreshPurchasedProducts()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [Self.proProductID])
            if products.isEmpty {
                statusMessage = "尚未連到 App Store Connect 商品，請確認 IAP 產品 ID 已建立。"
            }
        } catch {
            statusMessage = "無法載入商品：\(error.localizedDescription)"
        }
    }

    func purchasePro() async {
        guard let product = products.first(where: { $0.id == Self.proProductID }) else {
            statusMessage = "目前找不到 Pro 商品。請先在 App Store Connect 建立 \(Self.proProductID)。"
            await loadProducts()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                statusMessage = "已解鎖國樂團練習室 Pro。"
            case .userCancelled:
                statusMessage = "已取消購買。"
            case .pending:
                statusMessage = "購買待處理，完成後會自動解鎖。"
            @unknown default:
                statusMessage = "購買狀態未知，請稍後重新整理。"
            }
        } catch {
            statusMessage = "購買失敗：\(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
            statusMessage = isProUnlocked ? "已恢復 Pro 解鎖。" : "此 Apple ID 尚未找到 Pro 購買紀錄。"
        } catch {
            statusMessage = "恢復購買失敗：\(error.localizedDescription)"
        }
    }

    func refreshPurchasedProducts() async {
        var purchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchasedIDs
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? await self.checkVerifiedOnMain(result) {
                    await MainActor.run {
                        _ = self.purchasedProductIDs.insert(transaction.productID)
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func checkVerifiedOnMain<T>(_ result: VerificationResult<T>) async throws -> T {
        try await MainActor.run {
            try checkVerified(result)
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
