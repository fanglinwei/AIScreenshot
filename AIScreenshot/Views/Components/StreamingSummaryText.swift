import SwiftUI

struct StreamingSummaryText: View {
    let text: String
    let isStreaming: Bool
    var placeholder = "正在等待 AI 总结..."

    private var displayText: String {
        text.isEmpty ? placeholder : text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if text.isEmpty, isStreaming {
                ThinkingIndicator()
                SkeletonLoadingView()
            } else {
                AIContentText(text: displayText)
            }

            if isStreaming, !text.isEmpty {
                HStack {
                    CursorView()
                    Spacer(minLength: 0)
                }
                .padding(.top, -8)
            }
        }
    }
}
