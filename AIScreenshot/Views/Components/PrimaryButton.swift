import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var isSuccess = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: isSuccess ? [DS.ColorToken.success, DS.ColorToken.success.opacity(0.8)] : [DS.ColorToken.primary, DS.ColorToken.primary2], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .shadow(color: DS.ColorToken.primary.opacity(0.25), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}
