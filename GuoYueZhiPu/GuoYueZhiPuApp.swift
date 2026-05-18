import SwiftUI

@main
struct GuoYueZhiPuApp: App {
    @StateObject private var store = OrchestraStore()
    @StateObject private var progressStore = LearningProgressStore()
    @StateObject private var premiumStore = PremiumStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(progressStore)
                .environmentObject(premiumStore)
        }
    }
}
