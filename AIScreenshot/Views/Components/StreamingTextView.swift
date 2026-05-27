import SwiftUI

struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool
    var placeholder = "正在等待 AI 总结..."
    var characterDelay: Duration = .milliseconds(22)
    var showsSkeleton = true

    @State private var renderedText = ""
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if renderedText.isEmpty {
                if isStreaming {
                    ThinkingIndicator()
                    if showsSkeleton {
                        SkeletonLoadingView()
                    }
                } else {
                    AIContentText(text: placeholder)
                }
            } else {
                AIContentText(text: renderedText)

                if isStreaming {
                    HStack {
                        CursorView()
                        Spacer(minLength: 0)
                    }
                    .padding(.top, -8)
                }
            }
        }
        .onAppear {
            renderedText = text
        }
        .onDisappear {
            animationTask?.cancel()
        }
        .onChange(of: text) { _, newValue in
            animate(to: newValue)
        }
        .onChange(of: isStreaming) { _, streaming in
            if !streaming {
                animationTask?.cancel()
                renderedText = text
            }
        }
    }

    private func animate(to newValue: String) {
        animationTask?.cancel()

        guard isStreaming else {
            renderedText = newValue
            return
        }

        guard newValue.hasPrefix(renderedText) else {
            renderedText = newValue
            return
        }

        let suffix = String(newValue.dropFirst(renderedText.count))
        guard !suffix.isEmpty else { return }

        animationTask = Task { @MainActor in
            for character in suffix {
                guard !Task.isCancelled else { return }
                renderedText.append(character)
                try? await Task.sleep(for: characterDelay)
            }
        }
    }
}
