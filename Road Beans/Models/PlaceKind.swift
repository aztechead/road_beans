import SwiftUI

enum PlaceKind: String, Codable, CaseIterable, Sendable {
    case coffeeShop
    case truckStop
    case gasStation
    case fastFood
    case other

    var displayName: String {
        switch self {
        case .coffeeShop: "Coffee Shop"
        case .truckStop: "Truck Stop"
        case .gasStation: "Gas Station"
        case .fastFood: "Fast Food"
        case .other: "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .coffeeShop: "cup.and.saucer.fill"
        case .truckStop: "truck.box.fill"
        case .gasStation: "fuelpump.fill"
        case .fastFood: "takeoutbag.and.cup.and.straw.fill"
        case .other: "mappin.and.ellipse"
        }
    }

    var accentColor: Color {
        switch self {
        case .coffeeShop: Color(red: 0.45, green: 0.27, blue: 0.18)
        case .truckStop: Color(red: 0.95, green: 0.65, blue: 0.18)
        case .gasStation: Color(red: 0.18, green: 0.62, blue: 0.62)
        case .fastFood: Color(red: 0.85, green: 0.25, blue: 0.22)
        case .other: Color(red: 0.45, green: 0.50, blue: 0.55)
        }
    }
}
