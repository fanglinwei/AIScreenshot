import SwiftUI

enum DS {
    enum ColorToken {
        static let primary = Color(red: 0.35, green: 0.24, blue: 0.96)
        static let primary2 = Color(red: 0.23, green: 0.51, blue: 0.96)
        static let background = Color(red: 0.97, green: 0.98, blue: 1.00)
        static let card = Color.white
        static let textPrimary = Color(red: 0.04, green: 0.07, blue: 0.16)
        static let textSecondary = Color(red: 0.42, green: 0.45, blue: 0.54)
        static let success = Color(red: 0.13, green: 0.80, blue: 0.43)
        static let border = Color.black.opacity(0.06)
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 32
    }
}

extension View {
    func cardStyle(radius: CGFloat = DS.Radius.lg) -> some View {
        self
            .padding(DS.Spacing.md)
            .background(DS.ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.07), radius: 18, y: 8)
    }
}
