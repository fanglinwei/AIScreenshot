import Foundation

enum SummaryMode: String, CaseIterable, Identifiable, Codable {
    case summary = "摘要"
    case translate = "翻译"
    case study = "学习笔记"
    case actionItems = "待办事项"

    var id: String { rawValue }

    var systemPrompt: String {
        switch self {
        case .summary:
            return "你是专业信息总结助手。用中文提炼 3-5 个重点，不要编造原文没有的信息。"
        case .translate:
            return "你是专业翻译助手。先翻译为自然中文，再用 3 条 bullet 总结重点。"
        case .study:
            return "你是学习笔记助手。把内容整理为概念解释、关键点、可复习的问题。"
        case .actionItems:
            return "你是执行事项整理助手。提炼待办事项、负责人、时间点；没有的信息请写未提及。"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case Self.summary.rawValue, "Summary":
            self = .summary
        case Self.translate.rawValue, "Translate":
            self = .translate
        case Self.study.rawValue, "Study Notes":
            self = .study
        case Self.actionItems.rawValue, "Action Items":
            self = .actionItems
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "未知的总结模式：\(value)")
        }
    }
}
