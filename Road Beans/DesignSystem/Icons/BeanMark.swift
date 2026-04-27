import SwiftUI

struct BeanMark: View {
    enum State: CaseIterable, Equatable {
        case empty
        case quarter
        case half
        case threeQuarter
        case full

        var fraction: Double {
            switch self {
            case .empty:
                0
            case .quarter:
                0.25
            case .half:
                0.5
            case .threeQuarter:
                0.75
            case .full:
                1
            }
        }
    }

    let state: State
    let size: CGFloat

    private var height: CGFloat { size * 1.35 }
    private var strokeWidth: CGFloat { max(size / 24 * 1.5, 0.75) }

    var body: some View {
        ZStack {
            BeanMarkShape()
                .stroke(Color.ink(.tertiary), lineWidth: strokeWidth)

            if state != .empty {
                BeanMarkShape()
                    .fill(Color.accent(.default))
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: size * state.fraction)
                    }
            }

            BeanCreaseShape()
                .stroke(
                    state == .full ? Color.surface(.raised) : Color.ink(.tertiary),
                    lineWidth: strokeWidth
                )
        }
        .frame(width: size, height: height)
        .accessibilityHidden(true)
    }

    static func state(forRating rating: Double, position: Int) -> State {
        let beanFraction = min(max(rating - Double(position), 0), 1)

        switch beanFraction {
        case 0:
            return .empty
        case 0..<0.375:
            return .quarter
        case 0.375..<0.625:
            return .half
        case 0.625..<0.875:
            return .threeQuarter
        default:
            return .full
        }
    }
}

private struct BeanMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let minX = rect.minX
        let minY = rect.minY

        var path = Path()
        path.move(to: CGPoint(x: minX + width * 0.52, y: minY + height * 0.03))
        path.addCurve(
            to: CGPoint(x: minX + width * 0.95, y: minY + height * 0.47),
            control1: CGPoint(x: minX + width * 0.78, y: minY + height * 0.04),
            control2: CGPoint(x: minX + width * 0.96, y: minY + height * 0.20)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.97),
            control1: CGPoint(x: minX + width * 0.94, y: minY + height * 0.76),
            control2: CGPoint(x: minX + width * 0.77, y: minY + height * 0.97)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.05, y: minY + height * 0.53),
            control1: CGPoint(x: minX + width * 0.22, y: minY + height * 0.97),
            control2: CGPoint(x: minX + width * 0.05, y: minY + height * 0.80)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.52, y: minY + height * 0.03),
            control1: CGPoint(x: minX + width * 0.05, y: minY + height * 0.24),
            control2: CGPoint(x: minX + width * 0.23, y: minY + height * 0.03)
        )
        path.closeSubpath()
        return path
    }
}

private struct BeanCreaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let minX = rect.minX
        let minY = rect.minY

        var path = Path()
        path.move(to: CGPoint(x: minX + width * 0.60, y: minY + height * 0.12))
        path.addCurve(
            to: CGPoint(x: minX + width * 0.42, y: minY + height * 0.88),
            control1: CGPoint(x: minX + width * 0.40, y: minY + height * 0.28),
            control2: CGPoint(x: minX + width * 0.65, y: minY + height * 0.65)
        )
        return path
    }
}

#Preview("Bean states") {
    HStack(spacing: RoadBeansSpacing.md) {
        ForEach(BeanMark.State.allCases, id: \.self) { state in
            BeanMark(state: state, size: 32)
        }
    }
    .padding()
    .background(Color.surface(.canvas))
}
