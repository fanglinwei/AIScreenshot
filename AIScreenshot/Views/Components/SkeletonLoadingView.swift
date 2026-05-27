import SwiftUI

struct SkeletonLoadingView: View {
    var lineCount = 4
    @State private var isBreathing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(DS.ColorToken.border.opacity(isBreathing ? 0.55 : 0.22))
                    .frame(
                        maxWidth: index == lineCount - 1 ? 180 : .infinity,
                        minHeight: 10,
                        maxHeight: 10,
                        alignment: .leading
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}
