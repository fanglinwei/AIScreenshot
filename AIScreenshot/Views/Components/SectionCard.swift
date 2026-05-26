import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    var trailing: AnyView? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Spacer()
                if let trailing { trailing }
            }
            content
        }
        .cardStyle()
    }
}
