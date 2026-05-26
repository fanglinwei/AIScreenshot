import Foundation

struct WidgetSnapshotItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let summary: String
    let mode: String
}

enum WidgetSnapshotStore {
    private static let appGroupID = "group.com.fun.AIScreenshot"
    private static let filename = "widget_recent_items.json"

    static func load() -> [WidgetSnapshotItem] {
        guard let data = try? Data(contentsOf: snapshotURL) else { return [] }
        return (try? JSONDecoder().decode([WidgetSnapshotItem].self, from: data)) ?? []
    }

    private static var snapshotURL: URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return containerURL.appendingPathComponent(filename)
    }
}
