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
