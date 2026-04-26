import SwiftUI

enum RoadBeansTheme {
    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 18
        static let control: CGFloat = 14
    }

    enum Shadow {
        static let card = Color.black.opacity(0.12)
        static let marker = Color.black.opacity(0.20)
    }
}

extension Color {
    static let beanForeground = Color.primary
    static let beanBackground = Color(UIColor.systemBackground)
    static let beanCanvas = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let beanInk = Color(red: 0.22, green: 0.13, blue: 0.08)
    static let beanCream = Color(red: 1.0, green: 0.86, blue: 0.58)
    static let beanRoast = Color(red: 0.46, green: 0.25, blue: 0.13)
    static let beanTrail = Color(red: 0.10, green: 0.38, blue: 0.36)
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

    static var roadBeansCaption: Font {
        .system(.caption, design: .rounded, weight: .semibold)
    }
}

private struct RoadBeansScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(
                    colors: [
                        .beanCanvas.opacity(0.85),
                        Color(UIColor.systemBackground),
                        .beanTrail.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
    }
}

extension View {
    func roadBeansScreenBackground() -> some View {
        modifier(RoadBeansScreenBackground())
    }
}
