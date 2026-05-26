import Foundation
import Combine
import UIKit

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [OCRResult] = []
    private let key = "ocr_history_items"

    init() { load() }

    func add(_ result: OCRResult) {
        items.insert(result, at: 0)
        save()
    }

    func add(_ result: OCRResult, image: UIImage) {
        var savedResult = result
        savedResult.imageFilename = saveImage(image, id: result.id)
        add(savedResult)
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            let removed = items.remove(at: index)
            removeImage(named: removed.imageFilename)
        }
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

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([OCRResult].self, from: data) else { return }
        items = decoded
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

    private func removeImage(named filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: imageDirectory.appendingPathComponent(filename))
    }
}
