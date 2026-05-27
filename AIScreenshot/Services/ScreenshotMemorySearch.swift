import Foundation

struct ScreenshotMemorySearch {
    static func search(_ records: [OCRResult], query: String) -> [OCRResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return records }

        return records.filter { record in
            matches(record, query: normalizedQuery)
        }
    }

    static func related(to record: OCRResult, in records: [OCRResult], limit: Int = 3) -> [OCRResult] {
        records
            .filter { $0.id != record.id }
            .map { candidate in
                (record: candidate, score: relatedScore(record, candidate))
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.record.createdAt > rhs.record.createdAt
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map(\.record)
    }

    static func tags(for type: ScreenshotType, ocrText: String, summary: String) -> [String] {
        var tags = Set<String>()
        tags.insert(type.rawValue)

        let text = "\(ocrText) \(summary)".lowercased()
        let candidates = [
            "swift", "xcode", "debug", "api", "email", "invoice", "meeting",
            "launch", "revenue", "chart", "table", "design", "pdf"
        ]
        for candidate in candidates where text.contains(candidate) {
            tags.insert(candidate)
        }

        return Array(tags).sorted()
    }

    static func matches(_ record: OCRResult, query: String) -> Bool {
        record.title.localizedCaseInsensitiveContains(query) ||
        record.ocrText.localizedCaseInsensitiveContains(query) ||
        record.summary.localizedCaseInsensitiveContains(query) ||
        record.screenshotType.rawValue.localizedCaseInsensitiveContains(query) ||
        record.screenshotType.displayName.localizedCaseInsensitiveContains(query) ||
        record.tags.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private static func relatedScore(_ lhs: OCRResult, _ rhs: OCRResult) -> Int {
        var score = 0

        if lhs.screenshotType == rhs.screenshotType {
            score += 4
        }

        let lhsTags = Set(lhs.tags.map { $0.lowercased() })
        let rhsTags = Set(rhs.tags.map { $0.lowercased() })
        score += lhsTags.intersection(rhsTags).count * 2

        let lhsTerms = searchableTerms(from: "\(lhs.title) \(lhs.ocrText) \(lhs.summary)")
        let rhsTerms = searchableTerms(from: "\(rhs.title) \(rhs.ocrText) \(rhs.summary)")
        score += min(lhsTerms.intersection(rhsTerms).count, 3)

        return score
    }

    private static func searchableTerms(from text: String) -> Set<String> {
        let separators = CharacterSet.alphanumerics.inverted
        return Set(
            text
                .lowercased()
                .components(separatedBy: separators)
                .filter { $0.count >= 4 }
        )
    }
}
