import SwiftUI

struct CopyButton: View {
    let text: String
    var title = "复制"

    @State private var copied = false
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            showCopiedState()
        } label: {
            Label(copied ? "已复制" : title, systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.caption.weight(.semibold))
                .foregroundStyle(copied ? DS.ColorToken.success : DS.ColorToken.primary)
                .contentTransition(.symbolEffect(.replace))
        }
        .disabled(text.isEmpty)
        .animation(.snappy(duration: 0.2), value: copied)
        .onDisappear {
            resetTask?.cancel()
        }
    }

    private func showCopiedState() {
        resetTask?.cancel()

        copied = true
        resetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            copied = false
        }
    }
}
