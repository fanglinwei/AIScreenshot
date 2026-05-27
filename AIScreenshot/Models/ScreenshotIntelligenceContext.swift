import Foundation

struct ScreenshotIntelligenceContext: Equatable, Codable {
    var suspectedIntent: String
    var visualUnderstanding: String
    var userNeed: String
    var analysisFocus: [String]
    var memoryHints: [String]

    static let empty = ScreenshotIntelligenceContext(
        suspectedIntent: "未知",
        visualUnderstanding: "仅能基于 OCR 文本和截图类型推断视觉上下文。",
        userNeed: "提炼重点并给出下一步建议。",
        analysisFocus: [],
        memoryHints: []
    )

    var promptBlock: String {
        """
        截图智能上下文：
        - 用户可能截图的原因：\(suspectedIntent)
        - 视觉/场景理解：\(visualUnderstanding)
        - 用户潜在需求：\(userNeed)
        - 本次重点分析能力：\(analysisFocus.isEmpty ? "通用截图理解" : analysisFocus.joined(separator: "、"))
        - 相关历史线索：\(memoryHints.isEmpty ? "暂无相关历史截图" : memoryHints.joined(separator: "；"))
        """
    }
}
