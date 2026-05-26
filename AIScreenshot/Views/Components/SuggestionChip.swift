import SwiftUI

struct SuggestionChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DS.ColorToken.primary.opacity(0.1))
                .foregroundStyle(DS.ColorToken.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
