import Foundation

enum ResultFunctionAction: String, CaseIterable, Identifiable, Hashable {
    case explain
    case translate
    case actionItems
    case debug
    case flashcards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explain:
            return "Explain"
        case .translate:
            return "Translate"
        case .actionItems:
            return "Action Items"
        case .debug:
            return "Debug"
        case .flashcards:
            return "Make Flashcards"
        }
    }

    var resultTitle: String {
        switch self {
        case .explain:
            return "解释结果"
        case .translate:
            return "翻译结果"
        case .actionItems:
            return "行动项"
        case .debug:
            return "调试建议"
        case .flashcards:
            return "闪卡"
        }
    }

    var systemImage: String {
        switch self {
        case .explain:
            return "lightbulb"
        case .translate:
            return "character.book.closed"
        case .actionItems:
            return "checklist"
        case .debug:
            return "wrench.and.screwdriver"
        case .flashcards:
            return "rectangle.stack"
        }
    }

    func prompt(screenshotType: ScreenshotType) -> String {
        switch self {
        case .explain:
            return """
            请基于当前截图类型（\(screenshotType.displayName)）、OCR 和已有 AI 理解，进一步解释这张截图。
            重点回答：
            - 用户为什么可能截这张图
            - 截图里的关键信息意味着什么
            - 非专业用户应该如何理解
            - 下一步最值得做什么
            """
        case .translate:
            return """
            请把截图中的重要内容翻译成中文。如果原文已经是中文，请翻译成自然英文。
            要求：
            - 保留关键术语、按钮、错误提示、金额、日期
            - 不逐字翻译无意义 OCR 乱码
            - 最后补充一句上下文说明
            """
        case .actionItems:
            return """
            请从截图中提取可执行行动项。
            要求：
            - 按优先级列出
            - 每条包含动作、对象、条件/截止时间（如有）
            - 区分“必须做”“可选做”“需要确认”
            - 如果没有明确行动项，请给出最合理的下一步
            """
        case .debug:
            return """
            请把这张截图当成 debug 线索分析。
            要求：
            - 如果是代码/错误/界面异常，给出可能原因、排查步骤和修复建议
            - 如果不是技术截图，说明无法直接 debug，并把问题转化为可检查清单
            - 不要编造截图中没有出现的 API、文件名或错误栈
            """
        case .flashcards:
            return """
            请把截图内容制作成学习闪卡。
            要求：
            - 输出 5 到 8 张卡片
            - 每张格式为：Q: 问题 / A: 答案
            - 覆盖概念、原因、风险、下一步动作
            - 跳过 OCR 乱码和不确定内容
            """
        }
    }

    func localOutput(screenshotType: ScreenshotType, ocrText: String, summary: String) -> String {
        let cleanOCR = ocrText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let source = summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? cleanOCR : summary
        let preview = String(source.prefix(360))

        switch self {
        case .explain:
            return """
            ## Explain
            这是一张\(screenshotType.displayName)截图。用户大概率想快速理解截图里的关键信息，以及下一步该怎么处理。

            ## What It Means
            \(preview.isEmpty ? "当前缺少可解释的文字内容。" : preview)

            ## Next Step
            - 结合原截图确认关键按钮、金额、错误提示或责任人。
            - 如需更深度解释，请配置 AI 服务后重新生成。
            """
        case .translate:
            return """
            ## Translate
            本地模式无法进行高质量跨语言翻译，但已提取可翻译内容：

            \(preview.isEmpty ? "未识别到可翻译文本。" : preview)

            ## Note
            配置 AI 服务后可保留语气、上下文和专业术语进行完整翻译。
            """
        case .actionItems:
            let candidates = actionCandidates(from: cleanOCR)
            return """
            ## Action Items
            \(candidates.isEmpty ? "- 检查截图中最重要的提示，并决定是否需要回复、保存、付款、修复或继续阅读。" : candidates.map { "- \($0)" }.joined(separator: "\n"))

            ## Need Confirm
            - 是否存在截止时间、责任人、金额或不可逆操作。
            """
        case .debug:
            return """
            ## Debug
            \(debugHint(for: screenshotType, text: cleanOCR))

            ## Checklist
            - 找到截图中的错误提示、状态码或异常文案。
            - 记录触发步骤和当前页面状态。
            - 对照最近改动或输入条件逐项排查。
            """
        case .flashcards:
            let cards = flashcards(from: preview, screenshotType: screenshotType)
            return """
            ## Flashcards
            \(cards.joined(separator: "\n\n"))
            """
        }
    }

    private func actionCandidates(from text: String) -> [String] {
        let snippets = text
            .split(whereSeparator: { ".。!！?？;；".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let keywords = ["继续", "取消", "保存", "回复", "支付", "付款", "更新", "修复", "确认", "click", "continue", "cancel", "save", "reply", "pay", "update", "fix"]
        return snippets
            .filter { snippet in keywords.contains { snippet.lowercased().contains($0) } }
            .prefix(5)
            .map { String($0.prefix(120)) }
    }

    private func debugHint(for type: ScreenshotType, text: String) -> String {
        if type == .code {
            return "这是代码截图，请优先检查报错行、调用栈、输入数据、异步/状态变化和最近改动。"
        }
        if text.lowercased().contains("error") || text.contains("错误") || text.contains("失败") {
            return "截图中出现错误/失败线索，请优先定位触发条件、错误提示和可重试操作。"
        }
        return "这不是典型代码截图，可把它当作问题现场：先确认页面状态、用户操作、系统提示和可恢复路径。"
    }

    private func flashcards(from text: String, screenshotType: ScreenshotType) -> [String] {
        let base = text.isEmpty ? "当前截图缺少可学习文本。" : text
        return [
            "Q: 这张截图属于什么类型？\nA: \(screenshotType.displayName)。",
            "Q: 这张截图最可能需要解决什么问题？\nA: 快速理解关键信息并决定下一步动作。",
            "Q: 截图中的核心内容是什么？\nA: \(String(base.prefix(120)))",
            "Q: 使用这张截图时要注意什么？\nA: OCR 可能有误，需要结合原图确认关键数字、按钮和上下文。",
            "Q: 下一步可以怎么做？\nA: 提取待办、解释风险、翻译内容，或继续追问。"
        ]
    }
}
