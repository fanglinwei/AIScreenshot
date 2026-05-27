import Foundation

struct PromptRouter {
    static func prompt(
        for type: ScreenshotType,
        ocrText: String,
        intelligenceContext: ScreenshotIntelligenceContext = .empty
    ) -> String {
        let instructions = instructions(for: type)
        let sectionHeadings = ResultInsight.Section.allCases
            .map { "          \($0.markdownHeading)" }
            .joined(separator: "\n")
        return """
        \(instructions)

        你的目标不是复述“图片里有什么文字”，而是理解“用户为什么截图”：
        - 先判断用户可能想解决的问题
        - 再结合截图类型、OCR 和视觉/场景线索推断真实需求
        - 最后给出可执行建议，而不只是摘要

        \(intelligenceContext.promptBlock)

        通用要求：
        - 使用中文输出
        - 不要编造 OCR 文本中没有的信息
        - 可基于截图类型和上下文做合理推断，但必须标明不确定性
        - 输出尽量清晰、简洁、可执行
        - 必须使用以下 Markdown 标题组织输出，缺少信息的 section 可写“未提及”：
        \(sectionHeadings)

        OCR 文本如下：

        \(PromptService.trimOCRText(ocrText))
        """
    }

    private static func instructions(for type: ScreenshotType) -> String {
        switch type {
        case .chat:
            return """
            这是聊天截图。
            请进行 conversation understanding：提炼对话结论、双方意图、明确待办、潜在情绪/立场和可能需要回复的内容。
            """
        case .code:
            return """
            这是代码截图。
            请进行 code debugging：解释代码用途、关键逻辑、错误线索、潜在风险和可落地修复建议。
            """
        case .social:
            return """
            这是社交媒体截图。
            请进行 social insight：总结核心观点、立场、争议点、互动信号、可信度线索和反方观点。
            """
        case .email:
            return """
            这是邮件截图。
            请进行 action extraction：提炼邮件重点、发件人诉求、截止时间、待办事项、风险和回复建议。
            """
        case .table:
            return """
            这是表格截图。
            请进行 table analysis：解读主要字段、关键数字、异常值、对比关系和可行动结论。
            """
        case .chart:
            return """
            这是图表截图。
            请进行 chart analysis：分析趋势、峰值或低点、关键对比、可能原因、决策含义和不确定性。
            """
        case .ui:
            return """
            这是界面截图。
            请进行 UI analysis：分析页面状态、主要操作、信息层级、用户下一步、可用性问题和误操作风险。
            """
        case .document:
            return """
            这是文档截图。
            请理解用户可能截取该段内容的原因，生成 TLDR、关键概念、重点段落含义和后续可跟进的问题。
            """
        case .pdf:
            return """
            这是 PDF 截图。
            请理解用户可能截取该页的原因，总结当前页内容、关键概念、页内结论和需要继续阅读的线索。
            """
        case .unknown:
            return """
            这是通用截图 OCR 内容。
            请优先进行 screenshot intent understanding，基于可见文字做稳健推断，提炼重点、风险和下一步建议。
            """
        }
    }
}
