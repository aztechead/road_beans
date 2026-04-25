import Foundation

enum DrinkCategory: String, Codable, CaseIterable, Sendable {
    case drip
    case latte
    case cappuccino
    case coldBrew
    case espresso
    case tea
    case other

    var displayName: String {
        switch self {
        case .drip: "Drip"
        case .latte: "Latte"
        case .cappuccino: "Cappuccino"
        case .coldBrew: "Cold Brew"
        case .espresso: "Espresso"
        case .tea: "Tea"
        case .other: "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .drip: "cup.and.saucer.fill"
        case .latte: "mug.fill"
        case .cappuccino: "mug.fill"
        case .coldBrew: "takeoutbag.and.cup.and.straw.fill"
        case .espresso: "cup.and.heat.waves.fill"
        case .tea: "leaf.fill"
        case .other: "questionmark.circle"
        }
    }
}
