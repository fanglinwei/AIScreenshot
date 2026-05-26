import SwiftUI
import UIKit

struct AIContentText: View {
    let text: String
    var placeholder: String?
    var style = Style.summary
    var lineLimit: Int?

    private var displayText: String {
        text.isEmpty ? (placeholder ?? "") : text
    }

    var body: some View {
        SelectableMarkdownTextView(text: displayText, style: style, lineLimit: lineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension AIContentText {
    struct Style: Equatable {
        var bodyFont: UIFont
        var headingFont: UIFont
        var subheadingFont: UIFont
        var bodyColor: UIColor
        var headingColor: UIColor
        var markerColor: UIColor
        var paragraphSpacing: CGFloat
        var lineSpacing: CGFloat

        static let summary = Style(
            bodyFont: .preferredFont(forTextStyle: .subheadline),
            headingFont: .preferredFont(forTextStyle: .headline),
            subheadingFont: .preferredFont(forTextStyle: .subheadline).weighted(.semibold),
            bodyColor: .aiTextSecondary,
            headingColor: .aiTextPrimary,
            markerColor: .aiTextSecondary,
            paragraphSpacing: 8,
            lineSpacing: 2
        )

        static let assistantChat = Style(
            bodyFont: .preferredFont(forTextStyle: .body),
            headingFont: .preferredFont(forTextStyle: .body).weighted(.semibold),
            subheadingFont: .preferredFont(forTextStyle: .body).weighted(.semibold),
            bodyColor: .aiTextPrimary,
            headingColor: .aiTextPrimary,
            markerColor: .aiTextSecondary,
            paragraphSpacing: 8,
            lineSpacing: 2
        )
    }
}

private struct SelectableMarkdownTextView: UIViewRepresentable {
    let text: String
    let style: AIContentText.Style
    let lineLimit: Int?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.attach(textView)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        guard
            context.coordinator.text != text ||
            context.coordinator.style != style ||
            context.coordinator.lineLimit != lineLimit
        else { return }
        context.coordinator.text = text
        context.coordinator.style = style
        context.coordinator.lineLimit = lineLimit
        textView.textContainer.maximumNumberOfLines = lineLimit ?? 0
        textView.textContainer.lineBreakMode = lineLimit == nil ? .byWordWrapping : .byTruncatingTail
        textView.attributedText = MarkdownAttributedTextBuilder.attributedString(from: text, style: style)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var text = ""
        var style = AIContentText.Style.summary
        var lineLimit: Int?
        private weak var textView: UITextView?
        private var clearSelectionObserver: NSObjectProtocol?

        func attach(_ textView: UITextView) {
            self.textView = textView
            guard clearSelectionObserver == nil else { return }

            clearSelectionObserver = NotificationCenter.default.addObserver(
                forName: .clearSelectableTextSelection,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.clearSelection()
            }
        }

        deinit {
            if let clearSelectionObserver {
                NotificationCenter.default.removeObserver(clearSelectionObserver)
            }
        }

        private func clearSelection() {
            guard let textView else { return }

            let textLength = textView.attributedText?.length ?? 0
            let location = min(max(textView.selectedRange.location, 0), textLength)
            textView.selectedRange = NSRange(location: location, length: 0)
            textView.resignFirstResponder()
        }
    }
}

private enum MarkdownAttributedTextBuilder {
    static func attributedString(from text: String, style: AIContentText.Style) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let blocks = MarkdownBlockParser.blocks(from: text)

        for (index, block) in blocks.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n"))
            }

            switch block {
            case let .heading(level, content):
                result.append(inlineAttributedString(
                    from: content,
                    font: level == 1 ? style.headingFont : style.subheadingFont,
                    color: style.headingColor,
                    style: style
                ))
            case let .bullet(content):
                result.append(NSAttributedString(
                    string: "\u{2022} ",
                    attributes: attributes(font: style.bodyFont, color: style.markerColor, style: style)
                ))
                result.append(inlineAttributedString(from: content, font: style.bodyFont, color: style.bodyColor, style: style))
            case let .numbered(number, content):
                result.append(NSAttributedString(
                    string: "\(number). ",
                    attributes: attributes(font: style.bodyFont, color: style.markerColor, style: style)
                ))
                result.append(inlineAttributedString(from: content, font: style.bodyFont, color: style.bodyColor, style: style))
            case let .paragraph(content):
                result.append(inlineAttributedString(from: content, font: style.bodyFont, color: style.bodyColor, style: style))
            }
        }

        return result
    }

    private static func inlineAttributedString(
        from content: String,
        font: UIFont,
        color: UIColor,
        style: AIContentText.Style
    ) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let parsed = try? AttributedString(markdown: content, options: options) else {
            return NSAttributedString(string: content, attributes: attributes(font: font, color: color, style: style))
        }

        let attributed = NSMutableAttributedString(attributedString: NSAttributedString(parsed))
        attributed.addBaseAttributes(font: font, color: color, style: style)
        return attributed
    }

    private static func attributes(font: UIFont, color: UIColor, style: AIContentText.Style) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = style.paragraphSpacing
        paragraph.lineSpacing = style.lineSpacing

        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    }
}

private enum MarkdownBlockParser {
    static func blocks(from text: String) -> [MarkdownBlock] {
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
                result.append(.numbered(number: numbered.number, content: numbered.content))
                continue
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        return result
    }

    private static func parseHeading(_ line: String) -> (level: Int, content: String)? {
        let hashes = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(hashes) else { return nil }

        let rest = line.dropFirst(hashes)
        guard rest.first == " " else { return nil }

        let content = rest.dropFirst().trimmingCharacters(in: .whitespaces)
        return content.isEmpty ? nil : (hashes, content)
    }

    private static func parseBullet(_ line: String) -> String? {
        for marker in ["- ", "* ", "+ ", "\u{2022} "] where line.hasPrefix(marker) {
            let content = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
            return content.isEmpty ? nil : String(content)
        }
        return nil
    }

    private static func parseNumbered(_ line: String) -> (number: Int, content: String)? {
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
            let number = Int(digits)
        else {
            return nil
        }

        let content = remainder.dropFirst(2).trimmingCharacters(in: .whitespaces)
        return content.isEmpty ? nil : (number, String(content))
    }
}

private enum MarkdownBlock {
    case heading(level: Int, content: String)
    case bullet(String)
    case numbered(number: Int, content: String)
    case paragraph(String)
}

private extension NSMutableAttributedString {
    func addBaseAttributes(font: UIFont, color: UIColor, style: AIContentText.Style) {
        let fullRange = NSRange(location: 0, length: length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = style.paragraphSpacing
        paragraph.lineSpacing = style.lineSpacing

        addAttribute(.foregroundColor, value: color, range: fullRange)
        addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

        enumerateAttribute(.font, in: fullRange) { value, range, _ in
            let existingFont = value as? UIFont
            addAttribute(.font, value: font.mergingTraits(from: existingFont), range: range)
        }
    }
}

private extension UIFont {
    func weighted(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    func mergingTraits(from other: UIFont?) -> UIFont {
        guard let other else { return self }

        var traits = fontDescriptor.symbolicTraits
        traits.formUnion(other.fontDescriptor.symbolicTraits)

        if let descriptor = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: pointSize)
        }
        return self
    }
}

private extension UIColor {
    static let aiTextPrimary = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.94, blue: 0.98, alpha: 1)
            : UIColor(red: 0.04, green: 0.07, blue: 0.16, alpha: 1)
    }

    static let aiTextSecondary = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.67, green: 0.70, blue: 0.78, alpha: 1)
            : UIColor(red: 0.42, green: 0.45, blue: 0.54, alpha: 1)
    }
}

extension Notification.Name {
    static let clearSelectableTextSelection = Notification.Name("clearSelectableTextSelection")
}

extension View {
    func clearsSelectableTextSelectionOnTap() -> some View {
        background(SelectableTextSelectionClearingHost())
    }
}

private struct SelectableTextSelectionClearingHost: UIViewRepresentable {
    func makeUIView(context: Context) -> SelectionClearingGestureHostView {
        let view = SelectionClearingGestureHostView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: SelectionClearingGestureHostView, context: Context) {
        uiView.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func clearSelection() {
            NotificationCenter.default.post(name: .clearSelectableTextSelection, object: nil)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            !(touch.view?.isDescendant(ofType: UITextView.self) ?? false)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

private final class SelectionClearingGestureHostView: UIView {
    weak var delegate: SelectableTextSelectionClearingHost.Coordinator?
    private weak var installedWindow: UIWindow?
    private var tapRecognizer: UITapGestureRecognizer?

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if let tapRecognizer, let installedWindow, installedWindow !== window {
            installedWindow.removeGestureRecognizer(tapRecognizer)
            self.tapRecognizer = nil
            self.installedWindow = nil
        }

        guard tapRecognizer == nil, let window else { return }

        let recognizer = UITapGestureRecognizer(target: delegate, action: #selector(SelectableTextSelectionClearingHost.Coordinator.clearSelection))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = delegate
        window.addGestureRecognizer(recognizer)
        tapRecognizer = recognizer
        installedWindow = window
    }

    deinit {
        if let tapRecognizer {
            installedWindow?.removeGestureRecognizer(tapRecognizer)
        }
    }
}

private extension UIView {
    func isDescendant<T: UIView>(ofType type: T.Type) -> Bool {
        var view: UIView? = self
        while let current = view {
            if current is T { return true }
            view = current.superview
        }
        return false
    }
}
