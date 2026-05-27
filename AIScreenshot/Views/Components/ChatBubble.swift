import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    var isStreaming = false

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 44) }

            VStack(alignment: .leading, spacing: 8) {
                if !isUser {
                    Label("AI 助手", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DS.ColorToken.primary)
                }

                HStack(alignment: .bottom, spacing: 4) {
                    messageText
                        .foregroundStyle(isUser ? .white : DS.ColorToken.textPrimary)
                        .textSelection(.enabled)

                    if isStreaming && !isUser {
                        CursorView()
                            .padding(.bottom, 2)
                    }
                }
            }
            .padding(14)
            .background(isUser ? DS.ColorToken.primary : DS.ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(isUser ? .clear : DS.ColorToken.border, lineWidth: 1)
            )

            if !isUser { Spacer(minLength: 44) }
        }
    }

    @ViewBuilder
    private var messageText: some View {
        let display = message.content.isEmpty ? "正在思考..." : message.content
        if isUser {
            Text(display)
                .font(.body)
                .foregroundStyle(.white)
        } else if message.content.isEmpty {
            Text(display)
                .font(.body)
                .foregroundStyle(DS.ColorToken.textPrimary)
        } else {
            AIContentText(text: display, style: .assistantChat)
        }
    }
}
