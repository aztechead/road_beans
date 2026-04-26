import Foundation

enum BeanSliderModel {
    static func snap(_ raw: Double, step: Double) -> Double {
        guard step > 0 else { return raw }

        let snapped = (raw / step).rounded(.toNearestOrAwayFromZero) * step
        return (snapped * 10).rounded(.toNearestOrAwayFromZero) / 10
    }

    static func clamp(_ raw: Double, range: ClosedRange<Double>) -> Double {
        min(max(raw, range.lowerBound), range.upperBound)
    }

    static func crossedWholeBoundary(from oldValue: Double, to newValue: Double) -> Bool {
        let lower = min(oldValue, newValue)
        let upper = max(oldValue, newValue)

        for boundary in stride(from: 1.0, through: 5.0, by: 1.0) {
            if boundary > lower && boundary <= upper {
                return true
            }
        }

        return false
    }

    static func accessibilityValueText(_ value: Double) -> String {
        String(format: "%.1f of 5", value)
    }
}
