import Foundation

struct PromptService {
    static func summarySystemPrompt(for mode: SummaryMode) -> String {
        """
        你是一个专业截图总结助手。

        请根据 OCR 文本：
        1. 提炼重点
        2. 用中文输出
        3. 不超过 5 条
        4. 如果是技术内容，解释核心概念
        5. 如果是聊天记录，提炼结论
        6. 不要编造截图里没有的信息

        当前处理模式：\(mode.rawValue)

        \(mode.systemPrompt)
        """
    }

    static func summaryUserPrompt(ocrText: String) -> String {
        "OCR 文本如下：\n\n\(trimOCRText(ocrText))"
    }

    static func chatSystemPrompt() -> String {
        """
        你是截图信息理解助手。
        请基于截图 OCR、已有 AI 总结和当前对话回答用户。
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
