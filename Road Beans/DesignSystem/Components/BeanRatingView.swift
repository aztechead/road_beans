import SwiftUI
import UIKit

struct BeanRatingView: View {
    @Binding var value: Double
    var size: CGFloat = 24
    var range: ClosedRange<Double> = 0...5
    var granularity: Double = 0.5
    var editable = true

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if size < 24 && !editable {
            collapsed
        } else {
            row
        }
    }

    private var collapsed: some View {
        HStack(spacing: RoadBeansSpacing.xs) {
            BeanMark(state: .full, size: size)

            Text(String(format: "%.1f", value))
                .roadBeansStyle(.labelM)
                .foregroundStyle(.ink(.secondary))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rating")
        .accessibilityValue(Self.accessibilityValue(value))
    }

    private var row: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    BeanMark(state: BeanMark.state(forRating: value, position: index), size: size)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .animation(
                            reduceMotion ? nil : RoadBeansMotion.default.delay(Double(index) * 0.06),
                            value: value
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(editable ? dragGesture(width: geometry.size.width) : nil)
            .accessibilityElement()
            .accessibilityLabel("Rating")
            .accessibilityHint(editable ? "Adjustable" : "")
            .accessibilityValue(Self.accessibilityValue(value))
            .accessibilityAdjustableAction(adjustAccessibilityValue)
        }
        .frame(height: max(44, size * 1.35))
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                updateValue(
                    Self.rating(
                        forDragX: Double(drag.location.x),
                        rowWidth: Double(width),
                        range: range,
                        granularity: granularity
                    )
                )
            }
    }

    private func updateValue(_ rawValue: Double) {
        let snapped = Self.snap(rawValue, range: range, granularity: granularity)

        guard snapped != value else { return }

        let crossedWhole = floor(value) != floor(snapped)
        if hapticsEnabled {
            UISelectionFeedbackGenerator().selectionChanged()
            if crossedWhole {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }

        value = snapped
    }

    private func adjustAccessibilityValue(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment:
            updateValue(value + granularity)
        case .decrement:
            updateValue(value - granularity)
        @unknown default:
            break
        }
    }

    static func snap(
        _ raw: Double,
        range: ClosedRange<Double> = 0...5,
        granularity: Double
    ) -> Double {
        let clamped = min(max(raw, range.lowerBound), range.upperBound)
        return min(max((clamped / granularity).rounded() * granularity, range.lowerBound), range.upperBound)
    }

    static func rating(
        forDragX x: Double,
        rowWidth: Double,
        range: ClosedRange<Double>,
        granularity: Double
    ) -> Double {
        let clampedX = min(max(x, 0), rowWidth)
        let fraction = rowWidth > 0 ? clampedX / rowWidth : 0
        let raw = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
        return snap(raw, range: range, granularity: granularity)
    }

    static func accessibilityValue(_ value: Double) -> String {
        let whole = Int(value.rounded(.down))
        let fraction = value - Double(whole)
        let suffix: String

        switch fraction {
        case 0:
            suffix = ""
        case 0.25:
            suffix = " and a quarter"
        case 0.5:
            suffix = " and a half"
        case 0.75:
            suffix = " and three quarters"
        default:
            suffix = String(format: " and %.2f", fraction)
        }

        return "\(whole)\(suffix) of 5 beans"
    }
}
