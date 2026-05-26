import SwiftUI
import UIKit

struct SelectableContentText: View {
    let text: String
    var placeholder: String?
    var parseMarkdown = false

    private var displayText: String {
        text.isEmpty ? (placeholder ?? "") : text
    }

    var body: some View {
        SelectablePlainTextView(
            text: displayText,
            parseMarkdown: parseMarkdown,
            isPlaceholder: text.isEmpty
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SelectablePlainTextView: UIViewRepresentable {
    let text: String
    let parseMarkdown: Bool
    let isPlaceholder: Bool

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
            context.coordinator.parseMarkdown != parseMarkdown ||
            context.coordinator.isPlaceholder != isPlaceholder
        else { return }

        context.coordinator.text = text
        context.coordinator.parseMarkdown = parseMarkdown
        context.coordinator.isPlaceholder = isPlaceholder
        textView.attributedText = attributedText
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(size.height))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private var attributedText: NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let color = isPlaceholder ? UIColor.secondaryLabel : UIColor.label
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        guard parseMarkdown, let parsed = try? AttributedString(markdown: text) else {
            return NSAttributedString(string: text, attributes: attributes)
        }

        let attributed = NSMutableAttributedString(attributedString: NSAttributedString(parsed))
        attributed.addAttributes(attributes, range: NSRange(location: 0, length: attributed.length))
        return attributed
    }

    final class Coordinator {
        var text = ""
        var parseMarkdown = false
        var isPlaceholder = false
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
