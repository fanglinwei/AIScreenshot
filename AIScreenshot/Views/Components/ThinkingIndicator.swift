import SwiftUI

struct ThinkingIndicator: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(DS.ColorToken.primary.opacity(0.16))
                    .frame(width: 34, height: 34)
                    .scaleEffect(pulse ? 1.18 : 0.92)
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DS.ColorToken.primary)
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(DS.ColorToken.primary.opacity(0.85))
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulse ? 1.0 + CGFloat(index) * 0.14 : 0.72)
                        .animation(
                            .easeInOut(duration: 0.7)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.12),
                            value: pulse
                        )
                }
            }

            Text("AI 正在理解截图...")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.ColorToken.textSecondary)
        }
        .onAppear { pulse = true }
    }
}
