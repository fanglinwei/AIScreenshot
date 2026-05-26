//
//  AIScreenshotApp.swift
//  AIScreenshot
//
//  Created by 方林威 on 2026/5/26.
//

import SwiftUI

@main
struct AIScreenshotApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = AppSettings()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var chatStore = ChatStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(historyStore)
                .environmentObject(chatStore)
                .task {
                    historyStore.importPendingSharedItems()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        historyStore.importPendingSharedItems()
                    }
                }
                .onOpenURL { _ in
                    historyStore.importPendingSharedItems()
                }
        }
    }
}
