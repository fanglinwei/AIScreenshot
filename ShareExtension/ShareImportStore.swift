import Foundation
import UIKit

enum ShareImportStore {
    static let appGroupID = "group.com.fun.AIScreenshot"
    static let importedURL = URL(string: "aiscreenshot://import")!

    private static let queueFilename = "shared_import_items.json"
    private static let imageDirectoryName = "SharedImportImages"

    static func save(image: UIImage, ocrText: String, summary: String) throws -> ShareImportItem {
        let id = UUID()
        let imageFilename = "\(id.uuidString).png"
        let imageURL = imageDirectoryURL.appendingPathComponent(imageFilename)
        guard let imageData = image.pngData() else {
            throw ShareImportError.invalidImageData
        }
        try imageData.write(to: imageURL, options: [.atomic])

        let cleanText = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ShareImportItem(
            id: id,
            createdAt: Date(),
            title: makeTitle(from: cleanText),
            ocrText: cleanText,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: .summary,
            imageFilename: imageFilename
        )

        var items = loadPendingItems()
        items.insert(item, at: 0)
        let data = try JSONEncoder().encode(items)
        try data.write(to: queueURL, options: [.atomic])
        return item
    }

    private static func loadPendingItems() -> [ShareImportItem] {
        guard let data = try? Data(contentsOf: queueURL) else { return [] }
        return (try? JSONDecoder().decode([ShareImportItem].self, from: data)) ?? []
    }

    private static func makeTitle(from text: String) -> String {
        if text.isEmpty { return "分享的截图" }
        return String(text.replacingOccurrences(of: "\n", with: " ").prefix(34))
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

enum ShareImportError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        "截图保存失败"
    }
}
