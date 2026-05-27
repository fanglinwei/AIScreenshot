import Foundation
import Combine
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareExtensionViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case recognizing
        case ready
        case saved
        case failed(String)
    }

    @Published var image: UIImage?
    @Published var ocrText = ""
    @Published var summary = ""
    @Published var state: State = .loading

    var statusText: String {
        switch state {
        case .loading:
            return "正在读取分享内容..."
        case .recognizing:
            return "正在识别截图文字..."
        case .ready:
            return "已生成总结，可保存到 App。"
        case .saved:
            return "已保存，正在打开 App..."
        case .failed(let message):
            return message
        }
    }

    var canSave: Bool {
        switch state {
        case .ready:
            return image != nil
        default:
            return false
        }
    }

    func load(from extensionContext: NSExtensionContext?) async {
        state = .loading

        do {
            guard let image = try await firstSharedImage(from: extensionContext) else {
                state = .failed("请选择一张截图后再分享。")
                return
            }

            self.image = image
            state = .recognizing
            ocrText = try await ShareOCRService.recognizeText(from: image)
            summary = try await ShareAIService(settings: .current).summarize(ocrText: ocrText)
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func save() {
        guard let image else { return }

        do {
            _ = try ShareImportStore.save(image: image, ocrText: ocrText, summary: summary)
            state = .saved
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func firstSharedImage(from extensionContext: NSExtensionContext?) async throws -> UIImage? {
        let attachments = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []

        for provider in attachments where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let image = try await loadImage(from: provider) {
                return image
            }
        }

        return nil
    }

    private func loadImage(from provider: NSItemProvider) async throws -> UIImage? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let image = item as? UIImage {
                    continuation.resume(returning: image)
                    return
                }

                if let data = item as? Data, let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                    return
                }

                if let url = item as? URL,
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }
}
