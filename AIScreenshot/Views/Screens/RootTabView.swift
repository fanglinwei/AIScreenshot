import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("首页", systemImage: "house") }
            NavigationStack { HistoryView() }
                .tabItem { Label("历史", systemImage: "clock") }
            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .tint(DS.ColorToken.primary)
    }
}
