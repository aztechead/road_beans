import SwiftUI

extension Color {
    static let beanForeground = Color.primary
    static let beanBackground = Color(UIColor.systemBackground)
}

extension Font {
    static var roadBeansHeadline: Font {
        .system(.title2, design: .rounded, weight: .semibold)
    }

    static var roadBeansBody: Font {
        .system(.body)
    }

    static var roadBeansNumeric: Font {
        .system(.title2, design: .rounded, weight: .bold).monospacedDigit()
    }
}
