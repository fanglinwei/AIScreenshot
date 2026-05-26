import SwiftUI

struct CopyButton: View {
    let text: String
    var title = "复制"

    var body: some View {
        Button {
            UIPasteboard.general.string = text
        } label: {
            Label(title, systemImage: "doc.on.doc")
                .font(.caption.weight(.semibold))
        }
        .disabled(text.isEmpty)
    }
}
