//
//  AIScreenshotApp.swift
//  AIScreenshot
//
//  Created by 方林威 on 2026/5/26.
//

import SwiftUI

@main
struct AIScreenshotApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var historyStore = HistoryStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(historyStore)
        }
    }
}
