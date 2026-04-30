import Foundation

struct BrewTasteProfileStage: Equatable {
    static let cycleDuration: TimeInterval = 5.1

    let title: String
    let detail: String
    let symbolName: String

    static func current(at elapsed: TimeInterval) -> BrewTasteProfileStage {
        let progress = progress(at: elapsed)
        switch progress {
        case 0..<0.33:
            return BrewTasteProfileStage(
                title: "Reading visits",
                detail: "Gathering saved stops, drinks, and tags.",
                symbolName: "text.magnifyingglass"
            )
        case 0..<0.65:
            return BrewTasteProfileStage(
                title: "Weighing ratings",
                detail: "Balancing high scores against low signals.",
                symbolName: "scalemass.fill"
            )
        default:
            return BrewTasteProfileStage(
                title: "Dialing in Radar",
                detail: "Preparing nearby picks from your profile.",
                symbolName: "dot.radiowaves.left.and.right"
            )
        }
    }

    static func progress(at elapsed: TimeInterval) -> Double {
        guard cycleDuration > 0 else { return 0 }
        let remainder = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        let normalized = remainder >= 0 ? remainder : remainder + cycleDuration
        return normalized / cycleDuration
    }
}
