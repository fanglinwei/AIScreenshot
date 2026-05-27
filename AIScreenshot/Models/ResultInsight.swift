import Foundation

struct ResultInsight: Equatable, Codable {
    enum Section: String, CaseIterable, Codable, Hashable {
        case summary
        case intent
        case visualUnderstanding
        case keyPoints
        case actions
        case explanation
        case risks
        case relatedQuestions

        nonisolated var title: String {
            NSLocalizedString(localizationKey, comment: "")
        }

        nonisolated var markdownHeading: String {
            "## \(title)"
        }

        nonisolated var normalizedHeadingAliases: [String] {
            localizedAliases.map(Self.normalizedHeading)
        }

        nonisolated static func matching(heading: String) -> Section? {
            let normalized = normalizedHeading(heading)
            return allCases.first {
                $0.normalizedHeadingAliases.contains(normalized)
            }
        }

        nonisolated static func localizedTitle(matching heading: String) -> String? {
            matching(heading: heading)?.title
        }

        nonisolated var systemImage: String {
            switch self {
            case .summary:
                return "sparkles"
            case .intent:
                return "scope"
            case .visualUnderstanding:
                return "eye.fill"
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

        private nonisolated var localizationKey: String {
            "result.section.\(rawValue)"
        }

        private nonisolated var aliasesLocalizationKey: String {
            "\(localizationKey).aliases"
        }

        private nonisolated var localizedAliases: [String] {
            NSLocalizedString(aliasesLocalizationKey, comment: "")
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        private nonisolated static func normalizedHeading(_ heading: String) -> String {
            heading
                .trimmingCharacters(in: CharacterSet(charactersIn: "#:： "))
                .lowercased()
        }
    }

    var summary: String = ""
    var intent: String = ""
    var visualUnderstanding: String = ""
    var keyPoints: [String] = []
    var actions: [String] = []
    var explanation: String = ""
    var risks: [String] = []
    var relatedQuestions: [String] = []

    init(
        summary: String = "",
        intent: String = "",
        visualUnderstanding: String = "",
        keyPoints: [String] = [],
        actions: [String] = [],
        explanation: String = "",
        risks: [String] = [],
        relatedQuestions: [String] = []
    ) {
        self.summary = summary
        self.intent = intent
        self.visualUnderstanding = visualUnderstanding
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
        intent = sections[.intent]?.joinedText ?? ""
        visualUnderstanding = sections[.visualUnderstanding]?.joinedText ?? ""
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
        case .intent:
            return intent
        case .visualUnderstanding:
            return visualUnderstanding
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
            return [.summary, .intent, .keyPoints, .actions, .relatedQuestions]
        case .code:
            return [.summary, .intent, .visualUnderstanding, .explanation, .risks, .actions, .relatedQuestions]
        case .social:
            return [.summary, .intent, .keyPoints, .explanation, .relatedQuestions]
        case .email:
            return [.summary, .intent, .keyPoints, .actions, .risks, .relatedQuestions]
        case .table, .chart:
            return [.summary, .intent, .visualUnderstanding, .keyPoints, .explanation, .risks, .actions, .relatedQuestions]
        case .ui:
            return [.summary, .intent, .visualUnderstanding, .keyPoints, .explanation, .risks, .actions]
        case .document, .pdf:
            return [.summary, .intent, .keyPoints, .explanation, .relatedQuestions]
        case .unknown:
            return [.summary, .intent, .keyPoints, .actions, .relatedQuestions]
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
        Section.matching(heading: line)
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
