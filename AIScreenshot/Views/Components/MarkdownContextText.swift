import SwiftUI

struct MarkdownContextText: View {
    let text: String
    var style = Style()

    var body: some View {
        VStack(alignment: .leading, spacing: style.spacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case let .heading(level, content):
                    inlineText(content)
                        .font(level == 1 ? style.headingFont : style.subheadingFont)
                        .foregroundStyle(style.headingColor)
                case let .bullet(content):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(style.bodyFont)
                            .foregroundStyle(style.markerColor)
                        inlineText(content)
                            .font(style.bodyFont)
                            .foregroundStyle(style.bodyColor)
                    }
                case let .numbered(index, content):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index).")
                            .font(style.bodyFont)
                            .foregroundStyle(style.markerColor)
                        inlineText(content)
                            .font(style.bodyFont)
                            .foregroundStyle(style.bodyColor)
                    }
                case let .paragraph(content):
                    inlineText(content)
                        .font(style.bodyFont)
                        .foregroundStyle(style.bodyColor)
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

    struct Style {
        var headingFont: Font = .headline
        var subheadingFont: Font = .subheadline.weight(.semibold)
        var bodyFont: Font = .subheadline
        var headingColor: Color = DS.ColorToken.textPrimary
        var bodyColor: Color = DS.ColorToken.textSecondary
        var markerColor: Color = DS.ColorToken.textSecondary
        var spacing: CGFloat = 8

        static let assistantChat = Style(
            headingFont: .body.weight(.semibold),
            subheadingFont: .body.weight(.semibold),
            bodyFont: .body,
            headingColor: DS.ColorToken.textPrimary,
            bodyColor: DS.ColorToken.textPrimary,
            markerColor: DS.ColorToken.textSecondary,
            spacing: 8
        )
    }
}
