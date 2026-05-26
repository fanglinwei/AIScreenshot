import SwiftUI

struct CursorView: View {
    @State private var isVisible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(DS.ColorToken.primary)
            .frame(width: 3, height: 18)
            .opacity(isVisible ? 1 : 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}
