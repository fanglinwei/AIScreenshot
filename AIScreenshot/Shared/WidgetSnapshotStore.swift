import Foundation

struct WidgetSnapshotItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let summary: String
    let mode: String
}

enum WidgetSnapshotStore {
    private static let filename = "widget_recent_items.json"

    static func save(_ results: [OCRResult]) {
        let items = results.prefix(5).map {
            WidgetSnapshotItem(
                id: $0.id,
                createdAt: $0.createdAt,
                title: $0.title,
                summary: $0.summary,
                mode: $0.mode.rawValue
            )
        }

        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: snapshotURL, options: [.atomic])
    }

    private static var snapshotURL: URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedImportStore.appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return containerURL.appendingPathComponent(filename)
    }
}
