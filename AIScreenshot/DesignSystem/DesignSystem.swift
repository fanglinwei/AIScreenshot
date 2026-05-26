import SwiftUI
import UIKit

enum DS {
    enum ColorToken {
        static let primary = Color(red: 0.35, green: 0.24, blue: 0.96)
        static let primary2 = Color(red: 0.23, green: 0.51, blue: 0.96)
        static let background = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1)
                : UIColor(red: 0.97, green: 0.98, blue: 1.00, alpha: 1)
        })
        static let card = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1)
                : UIColor.white
        })
        static let elevatedCard = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.13, green: 0.14, blue: 0.20, alpha: 1)
                : UIColor(white: 1, alpha: 0.88)
        })
        static let textPrimary = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.93, green: 0.94, blue: 0.98, alpha: 1)
                : UIColor(red: 0.04, green: 0.07, blue: 0.16, alpha: 1)
        })
        static let textSecondary = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.67, green: 0.70, blue: 0.78, alpha: 1)
                : UIColor(red: 0.42, green: 0.45, blue: 0.54, alpha: 1)
        })
        static let success = Color(red: 0.13, green: 0.80, blue: 0.43)
        static let border = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.10)
                : UIColor.black.withAlphaComponent(0.06)
        })
        static let cardShadow = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.22)
                : UIColor.black.withAlphaComponent(0.07)
        })
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
            .shadow(color: DS.ColorToken.cardShadow, radius: 18, y: 8)
    }
}
