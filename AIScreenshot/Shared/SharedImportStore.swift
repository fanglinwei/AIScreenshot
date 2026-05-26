import Foundation

enum SharedImportStore {
    static let appGroupID = "group.com.fun.AIScreenshot"
    static let importedURL = URL(string: "aiscreenshot://import")!

    private static let queueFilename = "shared_import_items.json"
    private static let imageDirectoryName = "SharedImportImages"

    static func loadPendingItems() -> [SharedImportItem] {
        guard let data = try? Data(contentsOf: queueURL) else { return [] }
        return (try? JSONDecoder().decode([SharedImportItem].self, from: data)) ?? []
    }

    static func removePendingItems() {
        try? FileManager.default.removeItem(at: queueURL)
        try? FileManager.default.removeItem(at: imageDirectoryURL)
    }

    static func imageURL(filename: String) -> URL {
        imageDirectoryURL.appendingPathComponent(filename)
    }

    private static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    private static var queueURL: URL {
        containerURL.appendingPathComponent(queueFilename)
    }

    private static var imageDirectoryURL: URL {
        let url = containerURL.appendingPathComponent(imageDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
