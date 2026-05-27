import Foundation

struct ResultInsight: Equatable, Codable {
    enum Section: String, CaseIterable, Codable, Hashable {
        case summary
        case keyPoints
        case actions
        case explanation
        case risks
        case relatedQuestions

        var title: String {
            switch self {
            case .summary:
                return "总结"
            case .keyPoints:
                return "关键点"
            case .actions:
                return "行动项"
            case .explanation:
                return "解释"
            case .risks:
                return "风险"
            case .relatedQuestions:
                return "相关问题"
            }
        }

        var systemImage: String {
            switch self {
            case .summary:
                return "sparkles"
            case .keyPoints:
                return "list.bullet"
            case .actions:
                return "checklist"
            case .explanation:
                return "lightbulb.fill"
            case .risks:
                return "exclamationmark.triangle.fill"
            case .relatedQuestions:
                return "questionmark.bubble.fill"
            }
        }
    }

    var summary: String = ""
    var keyPoints: [String] = []
    var actions: [String] = []
    var explanation: String = ""
    var risks: [String] = []
    var relatedQuestions: [String] = []

    init(
        summary: String = "",
        keyPoints: [String] = [],
        actions: [String] = [],
        explanation: String = "",
        risks: [String] = [],
        relatedQuestions: [String] = []
    ) {
        self.summary = summary
        self.keyPoints = keyPoints
        self.actions = actions
        self.explanation = explanation
        self.risks = risks
        self.relatedQuestions = relatedQuestions
    }

    init(markdown: String) {
        let sections = Self.sections(from: markdown)
        guard !sections.isEmpty else {
            self.summary = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
            return
        }

        summary = sections[.summary]?.joinedText ?? ""
        keyPoints = sections[.keyPoints]?.items ?? []
        actions = sections[.actions]?.items ?? []
        explanation = sections[.explanation]?.joinedText ?? ""
        risks = sections[.risks]?.items ?? []
        relatedQuestions = sections[.relatedQuestions]?.items ?? []

        if summary.isEmpty {
            summary = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func content(for section: Section) -> String {
        switch section {
        case .summary:
            return summary
        case .keyPoints:
            return keyPoints.markdownList
        case .actions:
            return actions.markdownList
        case .explanation:
            return explanation
        case .risks:
            return risks.markdownList
        case .relatedQuestions:
            return relatedQuestions.markdownList
        }
    }

    func hasContent(for section: Section) -> Bool {
        !content(for: section).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func visibleSections(for type: ScreenshotType) -> [Section] {
        switch type {
        case .chat:
            return [.summary, .keyPoints, .actions, .relatedQuestions]
        case .code:
            return [.summary, .explanation, .risks, .actions, .relatedQuestions]
        case .social:
            return [.summary, .keyPoints, .explanation, .relatedQuestions]
        case .email:
            return [.summary, .keyPoints, .actions, .risks, .relatedQuestions]
        case .table, .chart:
            return [.summary, .keyPoints, .explanation, .risks, .relatedQuestions]
        case .ui:
            return [.summary, .keyPoints, .explanation, .risks, .actions]
        case .document, .pdf:
            return [.summary, .keyPoints, .explanation, .relatedQuestions]
        case .unknown:
            return [.summary, .keyPoints, .actions, .relatedQuestions]
        }
    }

    private static func sections(from markdown: String) -> [Section: [String]] {
        var result: [Section: [String]] = [:]
        var currentSection: Section?

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if let section = section(fromHeading: line) {
                currentSection = section
                if result[section] == nil {
                    result[section] = []
                }
                continue
            }

            guard let currentSection else { continue }
            result[currentSection, default: []].append(line)
        }

        return result
    }

    private static func section(fromHeading line: String) -> Section? {
        let normalized = line
            .trimmingCharacters(in: CharacterSet(charactersIn: "#:： "))
            .lowercased()

        switch normalized {
        case "summary", "总结", "摘要":
            return .summary
        case "key points", "keypoints", "关键点", "重点":
            return .keyPoints
        case "actions", "action items", "行动项", "待办", "待办事项":
            return .actions
        case "explanation", "解释", "说明":
            return .explanation
        case "risks", "风险", "风险点":
            return .risks
        case "related questions", "relatedquestions", "相关问题", "追问":
            return .relatedQuestions
        default:
            return nil
        }
    }
}

private extension Array where Element == String {
    var joinedText: String {
        map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var items: [String] {
        map { line in
            line
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-•*0123456789.、) "))
        }
        .filter { !$0.isEmpty }
    }

    var markdownList: String {
        map { "- \($0)" }.joined(separator: "\n")
    }
}
