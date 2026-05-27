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

    static let empty = WidgetSnapshotPayload(items: [], totalCount: 0, todayCount: 0, updatedAt: Date())
}

enum WidgetSnapshotStore {
    private static let appGroupID = "group.com.fun.AIScreenshot"
    private static let filename = "widget_recent_items.json"

    static func load() -> WidgetSnapshotPayload {
        guard let data = try? Data(contentsOf: snapshotURL) else { return .empty }

        if let payload = try? JSONDecoder().decode(WidgetSnapshotPayload.self, from: data) {
            return payload
        }

        if let legacyItems = try? JSONDecoder().decode([LegacyWidgetSnapshotItem].self, from: data) {
            let items = legacyItems.map {
                WidgetSnapshotItem(
                    id: $0.id,
                    createdAt: $0.createdAt,
                    title: $0.title,
                    summary: $0.summary,
                    mode: $0.mode,
                    ocrPreview: ""
                )
            }
            return WidgetSnapshotPayload(items: items, totalCount: items.count, todayCount: items.filter { Calendar.current.isDateInToday($0.createdAt) }.count, updatedAt: Date())
        }

        return .empty
    }

    private static var snapshotURL: URL {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return containerURL.appendingPathComponent(filename)
    }
}

private struct LegacyWidgetSnapshotItem: Codable {
    let id: UUID
    let createdAt: Date
    let title: String
    let summary: String
    let mode: String
}
