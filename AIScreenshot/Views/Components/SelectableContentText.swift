import SwiftUI

struct SelectableContentText: View {
    let text: String
    var placeholder: String?
    var parseMarkdown = false

    private var displayText: String {
        text.isEmpty ? (placeholder ?? "") : text
    }

    var body: some View {
        Group {
            if parseMarkdown, let markdown = try? AttributedString(markdown: displayText) {
                Text(markdown)
            } else {
                Text(displayText)
            }
        }
        .font(.body)
        .foregroundStyle(text.isEmpty ? .secondary : .primary)
        .textSelection(.enabled)
    }
}
