import Foundation

struct ScreenshotClassifier {
    static func classify(ocrText: String) -> ScreenshotType {
        let text = normalizedText(ocrText)
        guard !text.isEmpty else { return .unknown }

        let scores = classificationScores(for: ocrText)
        let rankedTypes: [ScreenshotType] = [
            .code,
            .email,
            .pdf,
            .chart,
            .table,
            .chat,
            .social,
            .ui,
            .document
        ]

        guard let bestType = rankedTypes.max(by: { (scores[$0] ?? 0) < (scores[$1] ?? 0) }),
              let bestScore = scores[bestType],
              bestScore >= 2 else {
            return .unknown
        }

        return bestType
    }

    static func classificationScores(for ocrText: String) -> [ScreenshotType: Int] {
        let text = normalizedText(ocrText)
        let lines = meaningfulLines(from: ocrText)
        let lowercaseLines = lines.map { $0.lowercased() }

        var scores: [ScreenshotType: Int] = [:]
        scores[.code] = codeScore(text: text, lines: lowercaseLines)
        scores[.email] = emailScore(text: text)
        scores[.pdf] = pdfScore(text: text)
        scores[.chart] = chartScore(text: text)
        scores[.table] = tableScore(text: text, lines: lowercaseLines)
        scores[.chat] = chatScore(text: text, lines: lines)
        scores[.social] = socialScore(text: text)
        scores[.ui] = uiScore(text: text)
        scores[.document] = documentScore(text: text, lines: lines)
        return scores
    }

    static func normalizedText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func meaningfulLines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func codeScore(text: String, lines: [String]) -> Int {
        var score = keywordScore(
            in: text,
            keywords: [
                "import ", "struct ", "class ", "func ", "let ", "var ", "enum ",
                "private ", "public ", "return ", "async", "await", "if let",
                "const ", "function ", "=>", "def ", "self.", "try await"
            ]
        )

        let symbolLines = lines.filter { line in
            line.contains("{") || line.contains("}") || line.contains(";") || line.contains("()")
        }.count
        if symbolLines >= 2 { score += 2 }
        if text.contains("swiftui") || text.contains("uikit") || text.contains("typescript") { score += 2 }
        return score
    }

    private static func emailScore(text: String) -> Int {
        var score = keywordScore(
            in: text,
            keywords: ["from:", "to:", "subject:", "cc:", "bcc:", "sent:", "regards", "best regards", "dear "]
        )
        if text.contains("@") && (text.contains(".com") || text.contains(".io") || text.contains(".cn")) {
            score += 1
        }
        return score
    }

    private static func pdfScore(text: String) -> Int {
        var score = keywordScore(
            in: text,
            keywords: ["pdf", "adobe acrobat", "acrobat reader", "preview", "page ", "页码"]
        )
        if text.contains("page ") && text.contains(" of ") { score += 3 }
        if text.contains(".pdf") { score += 3 }
        return score
    }

    private static func chartScore(text: String) -> Int {
        var score = keywordScore(
            in: text,
            keywords: [
                "chart", "graph", "axis", "legend", "trend", "bar chart",
                "line chart", "pie chart", "折线图", "柱状图", "图例", "趋势"
            ]
        )
        if text.contains("%") { score += 1 }
        if keywordScore(in: text, keywords: ["q1", "q2", "q3", "q4"]) >= 2 { score += 1 }
        return score
    }

    private static func tableScore(text: String, lines: [String]) -> Int {
        var score = keywordScore(
            in: text,
            keywords: ["total", "amount", "price", "revenue", "cost", "margin", "数量", "金额", "合计"]
        )

        let numericRows = lines.filter { line in
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "," })
            let numericParts = parts.filter { part in
                part.contains { $0.isNumber }
            }
            return parts.count >= 3 && numericParts.count >= 2
        }.count

        if numericRows >= 2 { score += 4 }
        if lines.count >= 3 && numericRows >= 1 { score += 1 }
        return score
    }

    private static func chatScore(text: String, lines: [String]) -> Int {
        var score = keywordScore(
            in: text,
            keywords: ["am", "pm", "昨天", "今天", "typing", "在线", "已读", "slack", "wechat", "imessage"]
        )

        let shortLines = lines.filter { $0.count <= 48 }.count
        if lines.count >= 4 && shortLines >= max(3, lines.count / 2) { score += 2 }
        if lines.contains(where: { containsTimeMarker($0) }) { score += 2 }
        return score
    }

    private static func socialScore(text: String) -> Int {
        var score = keywordScore(
            in: text,
            keywords: [
                "like", "likes", "repost", "reposts", "retweet", "followers",
                "following", "comment", "comments", "share", "views", "follow",
                "赞", "转发", "评论", "关注"
            ]
        )
        if text.contains("@") || text.contains("#") { score += 1 }
        return score
    }

    private static func uiScore(text: String) -> Int {
        keywordScore(
            in: text,
            keywords: [
                "settings", "sign in", "log in", "continue", "cancel", "done",
                "save", "edit", "tab", "home", "search", "profile", "button",
                "设置", "登录", "继续", "取消", "保存", "编辑", "首页", "搜索"
            ]
        )
    }

    private static func documentScore(text: String, lines: [String]) -> Int {
        var score = keywordScore(
            in: text,
            keywords: [
                "introduction", "abstract", "summary", "chapter", "section",
                "methodology", "conclusion", "references", "报告", "章节", "摘要", "结论"
            ]
        )

        let sentenceMarkers = text.filter { ".。!?！？".contains($0) }.count
        let longLines = lines.filter { $0.count >= 72 }.count
        if sentenceMarkers >= 2 { score += 1 }
        if longLines >= 2 || text.count >= 180 { score += 1 }
        return score
    }

    private static func keywordScore(in text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { score, keyword in
            text.contains(keyword) ? score + 1 : score
        }
    }

    private static func containsTimeMarker(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        if lowercased.contains("am") || lowercased.contains("pm") { return true }

        let parts = lowercased.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0].suffix(2)),
              hour >= 0,
              hour <= 23 else {
            return false
        }
        return parts[1].prefix(2).allSatisfy { $0.isNumber }
    }
}
