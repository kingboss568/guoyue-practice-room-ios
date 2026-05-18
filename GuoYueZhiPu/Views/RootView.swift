import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: OrchestraStore

    var body: some View {
        Group {
            if store.isLoaded {
                MainTabView()
            } else if let loadError = store.loadError {
                EmptyStateView(
                    title: "資料載入失敗",
                    message: loadError,
                    systemImage: "exclamationmark.triangle"
                )
            } else {
                ProgressView("載入國樂資料")
            }
        }
    }
}

private struct MainTabView: View {
    @State private var selectedTab: AppTab

    init() {
        _selectedTab = State(initialValue: AppTab.screenshotInitialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("總覽", systemImage: "music.note.house")
                }
                .tag(AppTab.dashboard)

            InstrumentsView()
                .tabItem {
                    Label("樂器", systemImage: "music.note.list")
                }
                .tag(AppTab.instruments)

            PiecesView()
                .tabItem {
                    Label("樂庫", systemImage: "record.circle")
                }
                .tag(AppTab.library)

            PracticeView()
                .tabItem {
                    Label("練功", systemImage: "target")
                }
                .tag(AppTab.practice)

            PremiumView()
                .tabItem {
                    Label("Pro", systemImage: "sparkles")
                }
                .tag(AppTab.pro)
        }
        .tint(AppTheme.cinnabar)
    }
}

private enum AppTab: String, Hashable {
    case dashboard
    case instruments
    case library
    case practice
    case pro

    static var screenshotInitialTab: AppTab {
        guard let tabName = ProcessInfo.processInfo.environment["GYZP_SCREENSHOT_TAB"] else {
            return .dashboard
        }
        return AppTab(rawValue: tabName) ?? .dashboard
    }
}
