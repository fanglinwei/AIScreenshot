import Foundation
import Combine
import UIKit
import WidgetKit

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [OCRResult] = []
    @Published var pendingImportedItem: OCRResult?
    private let key = "ocr_history_items"

    init() { load() }

    @discardableResult
    func add(_ result: OCRResult) -> OCRResult {
        items.insert(result, at: 0)
        save()
        return result
    }

    @discardableResult
    func add(_ result: OCRResult, image: UIImage) -> OCRResult {
        var savedResult = result
        savedResult.imageFilename = saveImage(image, id: result.id)
        savedResult.imagePath = imagePath(for: savedResult.imageFilename)
        add(savedResult)
        return savedResult
    }

    func importPendingSharedItems() {
        let sharedItems = SharedImportStore.loadPendingItems()
        guard !sharedItems.isEmpty else { return }

        let existingIDs = Set(items.map(\.id))
        var importedItems: [OCRResult] = []
        for sharedItem in sharedItems where !existingIDs.contains(sharedItem.id) {
            let result = OCRResult(
                id: sharedItem.id,
                createdAt: sharedItem.createdAt,
                title: sharedItem.title,
                ocrText: sharedItem.ocrText,
                summary: sharedItem.summary,
                mode: sharedItem.mode,
                screenshotType: ScreenshotClassifier.classify(ocrText: sharedItem.ocrText)
            )

            if let filename = sharedItem.imageFilename,
               let image = UIImage(contentsOfFile: SharedImportStore.imageURL(filename: filename).path) {
                importedItems.append(add(result, image: image))
            } else {
                importedItems.append(add(result))
            }
        }

        SharedImportStore.removePendingItems()
        pendingImportedItem = importedItems.first
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            let removed = items.remove(at: index)
            removeImage(named: removed.imageFilename)
        }
        save()
    }

    func delete(_ results: [OCRResult]) {
        let ids = Set(results.map(\.id))
        items
            .filter { ids.contains($0.id) }
            .forEach { removeImage(named: $0.imageFilename) }
        items.removeAll { ids.contains($0.id) }
        save()
    }

    func clear() {
        items.forEach { removeImage(named: $0.imageFilename) }
        items.removeAll()
        save()
    }

    func image(for item: OCRResult) -> UIImage? {
        guard let filename = item.imageFilename else { return nil }
        return UIImage(contentsOfFile: imageDirectory.appendingPathComponent(filename).path)
    }

    func search(_ query: String) -> [OCRResult] {
        ScreenshotMemorySearch.search(items, query: query)
    }

    func related(to item: OCRResult, limit: Int = 3) -> [OCRResult] {
        ScreenshotMemorySearch.related(to: item, in: items, limit: limit)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
        WidgetSnapshotStore.save(items)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([OCRResult].self, from: data) else { return }
        items = decoded.map { record in
            var migrated = record
            if migrated.screenshotType == .unknown {
                migrated.screenshotType = ScreenshotClassifier.classify(ocrText: migrated.ocrText)
            }
            if migrated.tags.isEmpty {
                migrated.tags = ScreenshotMemorySearch.tags(for: migrated.screenshotType, ocrText: migrated.ocrText, summary: migrated.summary)
            }
            if migrated.imagePath == nil {
                migrated.imagePath = imagePath(for: migrated.imageFilename)
            }
            return migrated
        }
        save()
    }

    private var imageDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("HistoryImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func saveImage(_ image: UIImage, id: UUID) -> String? {
        let filename = "\(id.uuidString).png"
        let url = imageDirectory.appendingPathComponent(filename)
        guard let data = image.pngData() else { return nil }

        do {
            try data.write(to: url, options: [.atomic])
            return filename
        } catch {
            return nil
        }
    }

    func imagePath(for filename: String?) -> String? {
        guard let filename else { return nil }
        return imageDirectory.appendingPathComponent(filename).path
    }

    private func removeImage(named filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: imageDirectory.appendingPathComponent(filename))
    }
}
