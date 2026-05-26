import SwiftUI

struct MarkdownContextText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case let .heading(level, content):
                    inlineText(content)
                        .font(level == 1 ? .headline : .subheadline.weight(.semibold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                case let .bullet(content):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.subheadline)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        inlineText(content)
                            .font(.subheadline)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                case let .numbered(index, content):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index).")
                            .font(.subheadline)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                        inlineText(content)
                            .font(.subheadline)
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                case let .paragraph(content):
                    inlineText(content)
                        .font(.subheadline)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                }
            }
        }
        .textSelection(.enabled)
    }

    private var blocks: [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            let paragraph = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !paragraph.isEmpty {
                result.append(.paragraph(paragraph))
            }
            paragraphLines.removeAll()
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if let heading = parseHeading(line) {
                flushParagraph()
                result.append(.heading(level: heading.level, content: heading.content))
                continue
            }

            if let bullet = parseBullet(line) {
                flushParagraph()
                result.append(.bullet(bullet))
                continue
            }

            if let numbered = parseNumbered(line) {
                flushParagraph()
                result.append(.numbered(index: numbered.index, content: numbered.content))
                continue
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        return result
    }

    private func inlineText(_ content: String) -> Text {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let markdown = try? AttributedString(markdown: content, options: options) {
            return Text(markdown)
        }
        return Text(content)
    }

    private func parseHeading(_ line: String) -> (level: Int, content: String)? {
        let hashes = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(hashes) else { return nil }

        let rest = line.dropFirst(hashes)
        guard rest.first == " " else { return nil }

        let content = rest.dropFirst().trimmingCharacters(in: .whitespaces)
        return content.isEmpty ? nil : (hashes, content)
    }

    private func parseBullet(_ line: String) -> String? {
        for marker in ["- ", "* ", "+ ", "• "] where line.hasPrefix(marker) {
            let content = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
            return content.isEmpty ? nil : String(content)
        }
        return nil
    }

    private func parseNumbered(_ line: String) -> (index: Int, content: String)? {
        var digits = ""
        var remainder = line[...]

        while let first = remainder.first, first.isNumber {
            digits.append(first)
            remainder = remainder.dropFirst()
        }

        guard
            let marker = remainder.first,
            marker == "." || marker == ")",
            remainder.dropFirst().first == " ",
            let index = Int(digits)
        else {
            return nil
        }

        let content = remainder.dropFirst(2).trimmingCharacters(in: .whitespaces)
        return content.isEmpty ? nil : (index, String(content))
    }

    private enum MarkdownBlock {
        case heading(level: Int, content: String)
        case bullet(String)
        case numbered(index: Int, content: String)
        case paragraph(String)
    }
}
