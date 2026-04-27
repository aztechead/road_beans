import SwiftUI

struct DrinkIcon: Shape {
    let category: DrinkCategory

    func path(in rect: CGRect) -> Path {
        switch category {
        case .drip:
            drip(rect)
        case .latte:
            mug(rect)
        case .cappuccino:
            mugWithFoam(rect)
        case .coldBrew:
            tallGlass(rect)
        case .espresso:
            demitasse(rect)
        case .tea:
            teacup(rect)
        case .other:
            circleQuestion(rect)
        }
    }

    private func drip(_ rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.closeSubpath()
        path.addRoundedRect(
            in: CGRect(x: rect.minX + rect.width * 0.25, y: rect.midY + 1, width: rect.width * 0.50, height: rect.height * 0.40),
            cornerSize: CGSize(width: 3, height: 3)
        )
        return path
    }

    private func mug(_ rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.25, width: rect.width * 0.50, height: rect.height * 0.55),
            cornerSize: CGSize(width: 3, height: 3)
        )
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.65, y: rect.midY - 4, width: rect.width * 0.20, height: rect.height * 0.30))
        return path
    }

    private func mugWithFoam(_ rect: CGRect) -> Path {
        var path = mug(rect)
        let foamY = rect.minY + rect.height * 0.30
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: foamY))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.62, y: foamY),
            control1: CGPoint(x: rect.minX + rect.width * 0.36, y: foamY - 3),
            control2: CGPoint(x: rect.minX + rect.width * 0.54, y: foamY + 3)
        )
        return path
    }

    private func tallGlass(_ rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.15, width: rect.width * 0.40, height: rect.height * 0.75),
            cornerSize: CGSize(width: 2, height: 2)
        )
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.10))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY + rect.height * 0.90))
        return path
    }

    private func demitasse(_ rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY + 2),
            radius: rect.width * 0.22,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.midY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.midY + rect.height * 0.30))
        return path
    }

    private func teacup(_ rect: CGRect) -> Path {
        var path = mug(rect)
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.10))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.10))
        return path
    }

    private func circleQuestion(_ rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.insetBy(dx: 2, dy: 2))
        path.move(to: CGPoint(x: rect.midX - 3, y: rect.midY - 2))
        path.addQuadCurve(to: CGPoint(x: rect.midX + 3, y: rect.midY - 2), control: CGPoint(x: rect.midX, y: rect.midY - 6))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + 2))
        path.move(to: CGPoint(x: rect.midX, y: rect.midY + 6))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + 6.5))
        return path
    }
}
