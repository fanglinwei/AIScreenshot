import SwiftUI
import UIKit
import Combine

@MainActor
final class ResultViewModel: ObservableObject {
    enum Step: String {
        case idle = "准备就绪"
        case ocr = "正在识别文字"
        case analyzing = "正在理解内容"
        case summary = "正在生成结果"
        case done = "已完成"
        case failed = "处理失败"
    }

    @Published var ocrText = ""
    @Published var summary = ""
    @Published var step: Step = .idle
    @Published var errorMessage: String?
    @Published var copied = false
    @Published var isStreamingSummary = false
    @Published var savedResultID: UUID?

    func process(image: UIImage, mode: SummaryMode, settings: AppSettings, historyStore: HistoryStore) async {
        do {
            errorMessage = nil
            summary = ""
            ocrText = ""
            savedResultID = nil
            isStreamingSummary = false

            step = .ocr
            let text = try await OCRService.recognizeText(from: image)
            ocrText = text

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                summary = "未识别到可总结的文字。"
                step = .done
                let result = OCRResult(title: makeTitle(from: text), ocrText: text, summary: summary, mode: mode)
                historyStore.add(result, image: image)
                savedResultID = result.id
                return
            }

            step = .analyzing
            try? await Task.sleep(nanoseconds: 250_000_000)

            step = .summary
            isStreamingSummary = true
            let service = OpenAIService(provider: settings.provider, apiKey: settings.activeAPIKey, model: settings.activeModel)
            for try await delta in service.streamSummary(text: text, mode: mode) {
                try Task.checkCancellation()
                summary += delta
            }
            isStreamingSummary = false

            step = .done
            let title = makeTitle(from: text)
            let result = OCRResult(title: title, ocrText: text, summary: summary, mode: mode)
            historyStore.add(result, image: image)
            savedResultID = result.id
            if settings.autoCopy { copyAll() }
        } catch is CancellationError {
            isStreamingSummary = false
        } catch {
            isStreamingSummary = false
            errorMessage = error.localizedDescription
            step = .failed
        }
    }

    func copyAll() {
        UIPasteboard.general.string = """
        识别文本：
        \(ocrText)

        AI 总结：
        \(summary)
        """
        copied = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            copied = false
        }
    }

    private func makeTitle(from text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { return "未命名截图" }
        return String(clean.prefix(34))
    }
}
