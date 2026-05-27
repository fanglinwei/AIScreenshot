import Foundation

struct WidgetSnapshotItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let summary: String
    let mode: String
    let ocrPreview: String
}

struct WidgetSnapshotPayload: Codable, Equatable {
    let items: [WidgetSnapshotItem]
    let totalCount: Int
    let todayCount: Int
    let updatedAt: Date
}

enum WidgetSnapshotStore {
    private static let filename = "widget_recent_items.json"

    static func save(_ results: [OCRResult]) {
        let calendar = Calendar.current
        let items = results.prefix(12).map {
            WidgetSnapshotItem(
                id: $0.id,
                createdAt: $0.createdAt,
                title: $0.title,
                summary: $0.summary,
                mode: $0.mode.rawValue,
                ocrPreview: String($0.ocrText.replacingOccurrences(of: "\n", with: " ").prefix(120))
            )
        }

        let payload = WidgetSnapshotPayload(
            items: items,
            totalCount: results.count,
            todayCount: results.filter { calendar.isDateInToday($0.createdAt) }.count,
            updatedAt: Date()
        )

        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: snapshotURL, options: [.atomic])
    }

    private static var snapshotURL: URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedImportStore.appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return containerURL.appendingPathComponent(filename)
    }
}
