import Foundation

enum TasteAxis: String, CaseIterable, Codable, Sendable {
    case roast
    case flavor
    case notes
    case body

    nonisolated var lowLabel: String {
        switch self {
        case .roast: "Light roast"
        case .flavor: "Bright / acidic"
        case .notes: "Fruity"
        case .body: "Light body"
        }
    }

    nonisolated var highLabel: String {
        switch self {
        case .roast: "Dark roast"
        case .flavor: "Chocolatey / mellow"
        case .notes: "Nutty"
        case .body: "Heavy body"
        }
    }

    nonisolated var compactLowLabel: String {
        switch self {
        case .roast: "Light"
        case .flavor: "Bright"
        case .notes: "Fruity"
        case .body: "Light body"
        }
    }

    nonisolated var compactHighLabel: String {
        switch self {
        case .roast: "Dark"
        case .flavor: "Mellow"
        case .notes: "Nutty"
        case .body: "Heavy"
        }
    }

    nonisolated var compactMidLabel: String {
        compactLabel(for: 0.5)
    }

    nonisolated func compactLabel(for value: Double) -> String {
        let band = switch min(max(value, 0), 1) {
        case ..<0.2: 0
        case ..<0.4: 1
        case ..<0.6: 2
        case ..<0.8: 3
        default: 4
        }

        return switch (self, band) {
        case (.roast, 0): "Light Roast"
        case (.roast, 1): "Toast Curious"
        case (.roast, 2): "Medium Roast"
        case (.roast, 3): "Campfire Roast"
        case (.roast, 4): "Midnight Roast"
        case (.flavor, 0): "Citrus Bright"
        case (.flavor, 1): "Bright Lean"
        case (.flavor, 2): "Smooth Middle"
        case (.flavor, 3): "Mellow Cocoa"
        case (.flavor, 4): "Dessert Mellow"
        case (.notes, 0): "Fruit Forward"
        case (.notes, 1): "Berry Tilt"
        case (.notes, 2): "Mixed Notes"
        case (.notes, 3): "Nutty Lean"
        case (.notes, 4): "Trail Mix Nutty"
        case (.body, 0): "Light Body"
        case (.body, 1): "Silky Body"
        case (.body, 2): "Medium Body"
        case (.body, 3): "Plush Body"
        case (.body, 4): "Heavy Body"
        default: "Medium"
        }
    }
}

struct TasteProfile: Codable, Sendable, Equatable {
    private(set) var axes: [String: Double]

    enum CodingKeys: String, CodingKey {
        case axes
    }

    nonisolated init(axes: [String: Double] = [:]) {
        self.axes = axes.mapValues(Self.clamp(_:))
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        axes = try container.decode([String: Double].self, forKey: .axes).mapValues(Self.clamp(_:))
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(axes, forKey: .axes)
    }

    nonisolated static var midpoint: TasteProfile {
        TasteProfile(
            axes: Dictionary(uniqueKeysWithValues: TasteAxis.allCases.map { ($0.rawValue, 0.5) })
        )
    }

    nonisolated func value(for axis: TasteAxis) -> Double {
        Self.clamp(axes[axis.rawValue] ?? 0.5)
    }

    nonisolated mutating func set(_ value: Double, for axis: TasteAxis) {
        axes[axis.rawValue] = Self.clamp(value)
    }

    nonisolated private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    nonisolated static func == (lhs: TasteProfile, rhs: TasteProfile) -> Bool {
        lhs.axes == rhs.axes
    }
}
