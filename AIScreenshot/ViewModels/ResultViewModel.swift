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
    @Published var screenshotType: ScreenshotType = .unknown
    @Published var intelligenceContext = ScreenshotIntelligenceContext.empty
    @Published var insight = ResultInsight()
    @Published var selectedFunction: ResultFunctionAction?
    @Published var functionOutputs: [ResultFunctionAction: String] = [:]
    @Published var isStreamingFunction = false

    var shareText: String {
        let functionText = functionOutputs
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.resultTitle)：\n\($0.value)" }
            .joined(separator: "\n\n")

        return """
        识别文本：
        \(ocrText)

        AI 总结：
        \(summary)
        \(functionText.isEmpty ? "" : "\n\n功能结果：\n\(functionText)")
        """
    }

    var currentMemoryRecord: OCRResult? {
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
              !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return OCRResult(
            id: savedResultID ?? UUID(),
            title: makeTitle(from: ocrText),
            ocrText: ocrText,
            summary: summary,
            mode: .summary,
            screenshotType: screenshotType,
            tags: ScreenshotMemorySearch.tags(for: screenshotType, ocrText: ocrText, summary: summary)
        )
    }

    func process(image: UIImage, mode: SummaryMode, settings: AppSettings, historyStore: HistoryStore) async {
        do {
            errorMessage = nil
            summary = ""
            ocrText = ""
            savedResultID = nil
            screenshotType = .unknown
            intelligenceContext = .empty
            insight = ResultInsight()
            selectedFunction = nil
            functionOutputs = [:]
            isStreamingFunction = false
            isStreamingSummary = false

            step = .ocr
            let text = try await OCRService.recognizeText(from: image)
            ocrText = text
            screenshotType = ScreenshotClassifier.classify(ocrText: text)
            intelligenceContext = makeIntelligenceContext(
                image: image,
                ocrText: text,
                screenshotType: screenshotType,
                historyStore: historyStore
            )

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                summary = """
                \(ResultInsight.Section.summary.markdownHeading)
                未识别到可总结的文字。

                \(ResultInsight.Section.intent.markdownHeading)
                \(intelligenceContext.suspectedIntent)

                \(ResultInsight.Section.visualUnderstanding.markdownHeading)
                \(intelligenceContext.visualUnderstanding)
                """
                insight = ResultInsight(markdown: summary)
                step = .done
                let result = OCRResult(
                    title: makeTitle(from: text),
                    ocrText: text,
                    summary: summary,
                    mode: mode,
                    screenshotType: screenshotType,
                    tags: ScreenshotMemorySearch.tags(for: screenshotType, ocrText: text, summary: summary)
                )
                let savedResult = historyStore.add(result, image: image)
                savedResultID = savedResult.id
                return
            }

            step = .analyzing
            try? await Task.sleep(nanoseconds: 250_000_000)

            step = .summary
            isStreamingSummary = true
            let service = OpenAIService(
                provider: settings.provider,
                apiKey: settings.activeAPIKey,
                model: settings.activeModel,
                baseURL: settings.activeBaseURL,
                fallbackToLocal: settings.fallbackToLocal
            )
            for try await delta in service.streamSummary(
                text: text,
                mode: mode,
                screenshotType: screenshotType,
                intelligenceContext: intelligenceContext
            ) {
                try Task.checkCancellation()
                summary += delta
                insight = ResultInsight(markdown: summary)
            }
            isStreamingSummary = false

            step = .done
            let title = makeTitle(from: text)
            let result = OCRResult(
                title: title,
                ocrText: text,
                summary: summary,
                mode: mode,
                screenshotType: screenshotType,
                tags: ScreenshotMemorySearch.tags(for: screenshotType, ocrText: text, summary: summary)
            )
            let savedResult = historyStore.add(result, image: image)
            savedResultID = savedResult.id
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
        UIPasteboard.general.string = shareText
        copied = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            copied = false
        }
    }

    func runFunction(_ action: ResultFunctionAction, settings: AppSettings) async {
        guard !isStreamingFunction else { return }
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
              !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        selectedFunction = action
        functionOutputs[action] = ""
        errorMessage = nil
        isStreamingFunction = true

        do {
            if settings.provider == .local || settings.activeAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let output = action.localOutput(screenshotType: screenshotType, ocrText: ocrText, summary: summary)
                for character in output {
                    try Task.checkCancellation()
                    functionOutputs[action, default: ""] += String(character)
                    try? await Task.sleep(nanoseconds: 18_000_000)
                }
                isStreamingFunction = false
                return
            }

            let service = OpenAIService(
                provider: settings.provider,
                apiKey: settings.activeAPIKey,
                model: settings.activeModel,
                baseURL: settings.activeBaseURL,
                fallbackToLocal: settings.fallbackToLocal
            )
            let messages = [
                ChatMessage(role: .user, content: action.prompt(screenshotType: screenshotType))
            ]

            for try await delta in service.streamChat(
                screenshotType: screenshotType,
                ocrText: ocrText,
                summary: summary,
                messages: messages
            ) {
                try Task.checkCancellation()
                functionOutputs[action, default: ""] += delta
            }
            isStreamingFunction = false
        } catch is CancellationError {
            isStreamingFunction = false
        } catch {
            isStreamingFunction = false
            errorMessage = error.localizedDescription
            if functionOutputs[action, default: ""].isEmpty {
                functionOutputs[action] = "生成失败，请稍后重试。"
            }
        }
    }

    private func makeTitle(from text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { return "未命名截图" }
        return String(clean.prefix(34))
    }

    private func makeIntelligenceContext(
        image: UIImage,
        ocrText: String,
        screenshotType: ScreenshotType,
        historyStore: HistoryStore
    ) -> ScreenshotIntelligenceContext {
        let provisionalRecord = OCRResult(
            title: makeTitle(from: ocrText),
            ocrText: ocrText,
            summary: "",
            mode: .summary,
            screenshotType: screenshotType,
            tags: ScreenshotMemorySearch.tags(for: screenshotType, ocrText: ocrText, summary: "")
        )

        return ScreenshotIntelligenceService.context(
            for: screenshotType,
            ocrText: ocrText,
            imageSize: image.size,
            relatedRecords: historyStore.related(to: provisionalRecord, limit: 3)
        )
    }
}
