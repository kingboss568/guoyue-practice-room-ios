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
        .task {
            await store.loadIfNeeded()
        }
    }
}

private struct MainTabView: View {
    @State private var selectedTab: AppTab

    init() {
        _selectedTab = State(initialValue: AppTab.screenshotInitialTab)
    }

    var body: some View {
        tabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AppTabBar(selectedTab: $selectedTab)
            }
            .tint(AppTheme.cinnabar)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .instruments:
            InstrumentsView()
        case .library:
            PiecesView()
        case .practice:
            PracticeView()
        case .pro:
            PremiumView()
        }
    }
}

private struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.title3.weight(.semibold))
                            .frame(height: 24)
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(selectedTab == tab ? AppTheme.cinnabar : .primary)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(AppTheme.cinnabar.opacity(0.12))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.separator).opacity(0.32), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

private enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case dashboard
    case instruments
    case library
    case practice
    case pro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "總覽"
        case .instruments:
            return "樂器"
        case .library:
            return "樂庫"
        case .practice:
            return "練功"
        case .pro:
            return "Pro"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "music.note.house"
        case .instruments:
            return "music.note.list"
        case .library:
            return "record.circle"
        case .practice:
            return "target"
        case .pro:
            return "sparkles"
        }
    }

    static var screenshotInitialTab: AppTab {
        guard let tabName = ProcessInfo.processInfo.environment["GYZP_SCREENSHOT_TAB"] else {
            return .dashboard
        }
        if tabName == "payment" {
            return .pro
        }
        return AppTab(rawValue: tabName) ?? .dashboard
    }
}
