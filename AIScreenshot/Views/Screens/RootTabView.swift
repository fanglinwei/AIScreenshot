import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("首页", systemImage: "house") }
                .tag(AppTab.home)
            NavigationStack { HistoryView() }
                .tabItem { Label("历史", systemImage: "clock") }
                .tag(AppTab.history)
            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(DS.ColorToken.primary)
        .onChange(of: historyStore.pendingImportedItem?.id) { _, itemID in
            if itemID != nil {
                selectedTab = .home
            }
        }
    }
}

private enum AppTab: Hashable {
    case home
    case history
    case settings
}
