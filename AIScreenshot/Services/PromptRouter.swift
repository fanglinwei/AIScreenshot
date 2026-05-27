import Foundation

struct PromptRouter {
    static func prompt(for type: ScreenshotType, ocrText: String) -> String {
        let instructions = instructions(for: type)
        return """
        \(instructions)

        通用要求：
        - 使用中文输出
        - 不要编造 OCR 文本中没有的信息
        - 如果信息不足，请明确说明
        - 输出尽量清晰、简洁、可执行
        - 必须使用以下 Markdown 标题组织输出，缺少信息的 section 可写“未提及”：
          ## Summary
          ## Key Points
          ## Actions
          ## Explanation
          ## Risks
          ## Related Questions

        OCR 文本如下：

        \(PromptService.trimOCRText(ocrText))
        """
    }

    private static func instructions(for type: ScreenshotType) -> String {
        switch type {
        case .chat:
            return """
            这是聊天截图。
            请提炼对话结论、双方意图、明确的待办事项和可能需要回复的内容。
            """
        case .code:
            return """
            这是代码截图。
            请解释代码用途、关键逻辑、潜在风险和可以改进的地方。
            """
        case .social:
            return """
            这是社交媒体截图。
            请总结核心观点、上下文线索、评论或互动中体现的态度。
            """
        case .email:
            return """
            这是邮件截图。
            请提炼邮件重点、发件人诉求、截止时间、待办事项和回复建议。
            """
        case .table:
            return """
            这是表格截图。
            请解读主要字段、关键数字、异常值、对比关系和可行动结论。
            """
        case .chart:
            return """
            这是图表截图。
            请分析趋势、峰值或低点、关键对比、可能结论和需要注意的不确定性。
            """
        case .ui:
            return """
            这是界面截图。
            请分析页面结构、主要操作、信息层级、可用性问题和优化建议。
            """
        case .document:
            return """
            这是文档截图。
            请生成 TLDR、关键概念、重点段落含义和后续可跟进的问题。
            """
        case .pdf:
            return """
            这是 PDF 截图。
            请总结当前页内容、关键概念、页内结论和可能需要继续阅读的线索。
            """
        case .unknown:
            return """
            这是通用截图 OCR 内容。
            请基于可见文字做稳健总结，提炼重点、风险和下一步建议。
            """
        }
    }
}
