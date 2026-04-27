import SwiftUI

enum RoadBeansFont {
    enum Style: CaseIterable, Sendable {
        case displayXL
        case displayL
        case displayM
        case numericDisplay
        case titleL
        case titleM
        case bodyL
        case bodyM
        case bodyS
        case labelL
        case labelM
        case eyebrow

        static var largeTitle: Style { .displayXL }
        static var title: Style { .displayL }
        static var title2: Style { .displayM }
        static var title3: Style { .titleL }
        static var headline: Style { .titleM }
        static var subheadline: Style { .bodyM }
        static var body: Style { .bodyL }
        static var callout: Style { .bodyM }
        static var label: Style { .labelL }
        static var caption: Style { .labelM }
        static var caption2: Style { .eyebrow }
        static var numeric: Style { .numericDisplay }

        var font: Font {
            let base: Font
            switch self {
            case .displayXL:
                base = .custom("NewYorkMedium-Regular", size: 40, relativeTo: .largeTitle)
            case .displayL:
                base = .custom("NewYorkMedium-Regular", size: 32, relativeTo: .title)
            case .displayM:
                base = .custom("NewYorkMedium-Regular", size: 24, relativeTo: .title2)
            case .numericDisplay:
                base = .custom("NewYorkMedium-Regular", size: 36, relativeTo: .largeTitle)
            case .titleL:
                base = .system(.title2, design: .default, weight: .semibold)
            case .titleM:
                base = .system(.body, design: .default, weight: .semibold)
            case .bodyL:
                base = .system(.body, design: .default, weight: .regular)
            case .bodyM:
                base = .system(.subheadline, design: .default, weight: .regular)
            case .bodyS:
                base = .system(.footnote, design: .default, weight: .regular)
            case .labelL:
                base = .system(.subheadline, design: .default, weight: .medium)
            case .labelM:
                base = .system(.footnote, design: .default, weight: .medium)
            case .eyebrow:
                base = .system(.caption2, design: .default, weight: .semibold)
            }
            return monospacedDigit ? base.monospacedDigit() : base
        }

        var tracking: CGFloat {
            switch self {
            case .displayXL, .displayL, .numericDisplay:
                -0.4
            case .displayM:
                -0.2
            case .labelM:
                0.15
            case .eyebrow:
                0.9
            default:
                0
            }
        }

        var transformsToUppercase: Bool {
            self == .eyebrow
        }

        var monospacedDigit: Bool {
            switch self {
            case .bodyL, .bodyM, .bodyS, .labelM, .numericDisplay:
                true
            default:
                false
            }
        }

        var maxDynamicTypeSize: DynamicTypeSize? {
            switch self {
            case .displayXL, .numericDisplay:
                .accessibility3
            default:
                nil
            }
        }
    }

    static func font(for style: Style) -> Font {
        style.font
    }
}

private struct RoadBeansStyleModifier: ViewModifier {
    let style: RoadBeansFont.Style

    @ViewBuilder
    func body(content: Content) -> some View {
        let base = content
            .font(style.font)
            .tracking(style.tracking)

        if style.transformsToUppercase, let cap = style.maxDynamicTypeSize {
            base.textCase(.uppercase).dynamicTypeSize(...cap)
        } else if style.transformsToUppercase {
            base.textCase(.uppercase)
        } else if let cap = style.maxDynamicTypeSize {
            base.dynamicTypeSize(...cap)
        } else {
            base
        }
    }
}

extension View {
    func roadBeansStyle(_ style: RoadBeansFont.Style) -> some View {
        modifier(RoadBeansStyleModifier(style: style))
    }
}
