import Foundation

struct ChatSuggestionProvider {
    static func suggestions(for type: ScreenshotType) -> [String] {
        switch type {
        case .code:
            return ["帮我调试", "解释报错", "给出修复建议"]
        case .chat:
            return ["提取结论", "帮我拟回复", "整理待办"]
        case .social, .document, .pdf:
            return ["帮我解释", "一句话总结", "找出反方观点"]
        case .email:
            return ["帮我拟回复", "整理待办", "一句话总结"]
        case .table, .chart:
            return ["帮我解释", "一句话总结", "提炼洞察"]
        case .ui:
            return ["帮我解释", "体验评审", "整理待办"]
        case .unknown:
            return ["帮我解释", "一句话总结", "整理待办"]
        }
    }
}
