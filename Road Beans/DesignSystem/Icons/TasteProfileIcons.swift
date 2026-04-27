import SwiftUI

struct TasteProfileIcon: Shape {
    let axis: TasteAxis

    func path(in rect: CGRect) -> Path {
        switch axis {
        case .roast:
            roast(rect)
        case .flavor:
            flavor(rect)
        case .notes:
            notes(rect)
        case .body:
            body(rect)
        }
    }

    private func roast(_ rect: CGRect) -> Path {
        var path = Path()
        for index in 0..<3 {
            let height = rect.height * CGFloat(index + 1) * 0.18
            let x = rect.minX + rect.width * (0.25 + CGFloat(index) * 0.18)
            path.addRoundedRect(in: CGRect(x: x, y: rect.maxY - height - rect.height * 0.15, width: rect.width * 0.10, height: height), cornerSize: CGSize(width: 2, height: 2))
        }
        return path
    }

    private func flavor(_ rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.midY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.35))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.65))
        return path
    }

    private func notes(_ rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.75))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.minY + rect.height * 0.22), control1: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.25), control2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.15))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.75), control1: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.65), control2: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.82))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.65))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.30))
        return path
    }

    private func body(_ rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.18, width: rect.width * 0.50, height: rect.height * 0.22))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.39, width: rect.width * 0.60, height: rect.height * 0.24))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.62, width: rect.width * 0.70, height: rect.height * 0.26))
        return path
    }
}
