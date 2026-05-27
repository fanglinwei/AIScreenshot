import Foundation

struct ScreenshotIntelligenceService {
    static func context(
        for type: ScreenshotType,
        ocrText: String,
        imageSize: CGSize? = nil,
        relatedRecords: [OCRResult] = []
    ) -> ScreenshotIntelligenceContext {
        ScreenshotIntelligenceContext(
            suspectedIntent: suspectedIntent(for: type, ocrText: ocrText),
            visualUnderstanding: visualUnderstanding(for: type, imageSize: imageSize),
            userNeed: userNeed(for: type),
            analysisFocus: analysisFocus(for: type),
            memoryHints: memoryHints(from: relatedRecords)
        )
    }

    static func suspectedIntent(for type: ScreenshotType, ocrText: String) -> String {
        let text = ScreenshotClassifier.normalizedText(ocrText)

        if containsAny(text, ["error", "exception", "failed", "crash", "报错", "失败", "异常"]) {
            return "用户可能想定位错误原因并获得修复建议。"
        }
        if containsAny(text, ["due", "deadline", "asap", "截止", "尽快", "今天", "明天"]) {
            return "用户可能想提取紧急事项、截止时间或待办。"
        }
        if containsAny(text, ["insufficient", "payment", "billing", "余额不足", "付款", "订阅"]) {
            return "用户可能想理解付款/订阅状态，并判断下一步操作风险。"
        }

        switch type {
        case .chat:
            return "用户可能想理解对话结论、对方真实诉求，以及自己是否需要回复或行动。"
        case .code:
            return "用户可能想理解代码含义、排查 bug，或获得更安全的实现建议。"
        case .social:
            return "用户可能想判断观点立场、争议点、可信度或可转述的洞察。"
        case .email:
            return "用户可能想快速识别邮件诉求、优先级、风险和回复策略。"
        case .table:
            return "用户可能想从数据中发现异常、对比关系和可行动结论。"
        case .chart:
            return "用户可能想理解趋势、变化原因和图表背后的业务含义。"
        case .ui:
            return "用户可能想知道当前界面在提示什么、下一步该点哪里，以及是否有体验或风险问题。"
        case .document, .pdf:
            return "用户可能想快速理解长内容的核心结论、概念和后续问题。"
        case .unknown:
            return "用户可能想保存重要信息，并获得简洁解释和下一步建议。"
        }
    }

    static func visualUnderstanding(for type: ScreenshotType, imageSize: CGSize?) -> String {
        let orientation: String
        if let imageSize, imageSize.width > imageSize.height * 1.15 {
            orientation = "横向截图，可能包含桌面窗口、表格、代码或图表。"
        } else if let imageSize, imageSize.height > imageSize.width * 1.15 {
            orientation = "纵向截图，可能来自手机页面、聊天、文章或应用界面。"
        } else {
            orientation = "接近方形截图，可能是局部裁剪内容。"
        }

        let scene: String
        switch type {
        case .chat:
            scene = "视觉重点通常是消息气泡、时间线和对话上下文。"
        case .code:
            scene = "视觉重点通常是代码块、错误输出、编辑器或终端结构。"
        case .social:
            scene = "视觉重点通常是作者、正文、互动数据和评论语境。"
        case .email:
            scene = "视觉重点通常是发件人、主题、正文、时间和回复按钮。"
        case .table:
            scene = "视觉重点通常是行列结构、数值密度和异常单元格。"
        case .chart:
            scene = "视觉重点通常是坐标轴、图例、峰值、低点和趋势方向。"
        case .ui:
            scene = "视觉重点通常是按钮、弹窗、导航、状态提示和主要操作路径。"
        case .document, .pdf:
            scene = "视觉重点通常是标题、段落层级、页码和引用位置。"
        case .unknown:
            scene = "视觉重点需结合 OCR 文本谨慎推断。"
        }

        return "\(orientation)\(scene)"
    }

    static func userNeed(for type: ScreenshotType) -> String {
        switch type {
        case .chat:
            return "提炼决定、待办、情绪/立场，并给出可发送的回复方向。"
        case .code:
            return "解释问题、定位风险、给出 debug 路径和修复建议。"
        case .social:
            return "总结观点、识别立场、补充反方视角和可分享洞察。"
        case .email:
            return "提取诉求、时间、责任人、风险和回复行动。"
        case .table:
            return "识别关键数字、异常、对比结论和下一步分析。"
        case .chart:
            return "解释趋势、变化、可能原因和决策提示。"
        case .ui:
            return "判断界面状态、下一步操作、潜在误操作和可用性问题。"
        case .document, .pdf:
            return "快速理解核心概念、结论、证据和后续追问。"
        case .unknown:
            return "解释截图价值，提炼可保存、可执行、可追问的信息。"
        }
    }

    static func analysisFocus(for type: ScreenshotType) -> [String] {
        switch type {
        case .chat:
            return ["conversation understanding", "action extraction"]
        case .code:
            return ["code debugging", "risk analysis", "fix suggestion"]
        case .social:
            return ["social insight", "counterpoints", "credibility signals"]
        case .email:
            return ["action extraction", "priority", "reply strategy"]
        case .table:
            return ["table analysis", "outlier detection", "actionable AI"]
        case .chart:
            return ["chart analysis", "trend interpretation", "decision insight"]
        case .ui:
            return ["UI analysis", "visual understanding", "next action"]
        case .document, .pdf:
            return ["document understanding", "concept explanation", "related questions"]
        case .unknown:
            return ["screenshot intent understanding", "actionable AI"]
        }
    }

    static func memoryHints(from records: [OCRResult]) -> [String] {
        records.prefix(3).map { record in
            let summary = record.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = summary.isEmpty ? record.title : summary
            return "\(record.screenshotType.displayName)：\(String(text.prefix(60)))"
        }
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
