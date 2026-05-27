import Foundation

struct PromptService {
    static func summarySystemPrompt(for mode: SummaryMode) -> String {
        """
        你是 Screenshot Intelligence 助手。

        你的任务不是简单复述 OCR，而是理解：
        1. 用户为什么截图
        2. 截图属于什么场景
        3. 用户可能想解决什么问题
        4. 哪些信息可以行动
        5. 哪些风险、不确定性或后续问题值得提醒

        请结合 ScreenshotClassifier 类型、OCR、视觉/场景线索和相关历史截图记忆进行分析。
        如果信息不足，可以做谨慎推断，但必须说明不确定性。

        当前处理模式：\(mode.rawValue)

        \(mode.systemPrompt)
        """
    }

    static func summaryUserPrompt(ocrText: String) -> String {
        "OCR 文本如下：\n\n\(trimOCRText(ocrText))"
    }

    static func chatSystemPrompt() -> String {
        """
        你是 Screenshot Intelligence 对话助手。
        请基于截图类型、截图意图、OCR、已有 AI 理解和当前对话回答用户。
        如果截图中没有相关信息，请明确说明，不要编造。
        回答使用中文，尽量清晰、简洁、可执行。
        """
    }

    static func chatContextPrompt(screenshotType: ScreenshotType, ocrText: String, summary: String) -> String {
        """
        截图类型：
        \(screenshotType.displayName)

        截图 OCR：
        \(trimOCRText(ocrText, maxCharacters: 8_000))

        已有 AI 总结：
        \(summary.trimmingCharacters(in: .whitespacesAndNewlines))
        """
    }

    static func trimOCRText(_ text: String, maxCharacters: Int = 12_000) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxCharacters else { return trimmed }

        let prefix = trimmed.prefix(maxCharacters)
        return """
        \(prefix)

        [内容较长，已优先分析前 \(maxCharacters) 个字符。]
        """
    }
}
