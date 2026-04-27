import SwiftUI

struct PlaceKindIcon: Shape {
    let kind: PlaceKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .coffeeShop:
            cafeFront(rect)
        case .truckStop:
            truckProfile(rect)
        case .gasStation:
            fuelPump(rect)
        case .fastFood:
            takeoutBag(rect)
        case .other:
            mapPin(rect)
        }
    }

    private func cafeFront(_ rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.35, width: rect.width * 0.70, height: rect.height * 0.55), cornerSize: CGSize(width: 2, height: 2))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.minY + rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.90, y: rect.minY + rect.height * 0.35))
        return path
    }

    private func truckProfile(_ rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.40, width: rect.width * 0.55, height: rect.height * 0.35), cornerSize: CGSize(width: 2, height: 2))
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.65, y: rect.minY + rect.height * 0.50, width: rect.width * 0.25, height: rect.height * 0.25), cornerSize: CGSize(width: 2, height: 2))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.72, width: rect.width * 0.14, height: rect.height * 0.14))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.72, width: rect.width * 0.14, height: rect.height * 0.14))
        return path
    }

    private func fuelPump(_ rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.20, width: rect.width * 0.40, height: rect.height * 0.65), cornerSize: CGSize(width: 3, height: 3))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.65, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.midY + rect.height * 0.18), control1: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.midY), control2: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.midY + rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.35))
        return path
    }

    private func takeoutBag(_ rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.32, width: rect.width * 0.56, height: rect.height * 0.55), cornerSize: CGSize(width: 3, height: 3))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.32))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.32), control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.12))
        return path
    }

    private func mapPin(_ rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.height * 0.20, width: rect.width * 0.36, height: rect.height * 0.36))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.88))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.20), control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.88), control: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.midY))
        return path
    }
}
