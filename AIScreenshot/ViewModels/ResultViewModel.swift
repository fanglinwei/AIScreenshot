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

    func process(image: UIImage, mode: SummaryMode, settings: AppSettings, historyStore: HistoryStore) async {
        do {
            step = .ocr
            let text = try await OCRService.recognizeText(from: image)
            ocrText = text

            step = .analyzing
            try? await Task.sleep(nanoseconds: 250_000_000)

            step = .summary
            let service = OpenAIService(provider: settings.provider, apiKey: settings.activeAPIKey, model: settings.activeModel)
            let result = try await service.summarize(text: text, mode: mode)
            summary = result

            step = .done
            let title = makeTitle(from: text)
            historyStore.add(OCRResult(title: title, ocrText: text, summary: result, mode: mode), image: image)
            if settings.autoCopy { copyAll() }
        } catch {
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
