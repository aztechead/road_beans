import SwiftUI
import UIKit

struct BeanSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...5
    var step: Double = 0.1

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var glyphPulse = false

    private let trackHeight: CGFloat = 14
    private let thumbDiameter: CGFloat = 52

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let progress = normalizedProgress
                let thumbX = min(max(width * CGFloat(progress), thumbDiameter / 2), width - thumbDiameter / 2)

                ZStack(alignment: .leading) {
                    track

                    BeanGlyph(beanCount: BeanGlyph.beanCount(for: value), pixelSize: 3)
                        .scaleEffect(glyphPulse && !reduceMotion ? 1.14 : 1)
                        .opacity(reduceMotion && glyphPulse ? 0.78 : 1)
                        .offset(x: thumbX - 24, y: -48)
                        .animation(reduceMotion ? .easeInOut(duration: 0.12) : .spring(response: 0.25, dampingFraction: 0.55), value: glyphPulse)
                        .animation(.easeInOut(duration: 0.12), value: BeanGlyph.beanCount(for: value))

                    thumb
                        .offset(x: thumbX - thumbDiameter / 2)
                }
                .contentShape(Rectangle())
                .gesture(dragGesture(width: width))
                .accessibilityElement()
                .accessibilityLabel("Drink rating")
                .accessibilityHint("Swipe up or down to adjust by one tenth of a bean.")
                .accessibilityValue(BeanSliderModel.accessibilityValueText(value))
                .accessibilityAdjustableAction(adjustAccessibilityValue)
            }
            .frame(height: 88)

            beanRow
        }
    }

    private var beanRow: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { i in
                BeanGlyph(beanCount: 1, pixelSize: 3)
                    .frame(maxWidth: .infinity)
                    .opacity(value >= Double(i) ? 1.0 : 0.25)
                    .animation(.easeInOut(duration: 0.1), value: value >= Double(i))
            }
        }
        .accessibilityHidden(true)
    }

    private var normalizedProgress: Double {
        let span = max(range.upperBound - range.lowerBound, .ulpOfOne)
        return BeanSliderModel.clamp((value - range.lowerBound) / span, range: 0...1)
    }

    private var track: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [.beanTrail.opacity(0.72), .beanCream.opacity(0.82), .beanRoast.opacity(0.78)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: trackHeight)
            .overlay(Capsule().strokeBorder(Color.beanInk.opacity(0.16), lineWidth: 1))
            .accessibilityHidden(true)
    }

    private var thumb: some View {
        ZStack {
            Circle()
                .fill(reduceTransparency ? Color.beanRoast.opacity(0.92) : Color.clear)
                .background {
                    if !reduceTransparency {
                        Circle().fill(.thinMaterial)
                    }
                }
                .overlay(Circle().strokeBorder(Color.beanCream.opacity(0.7), lineWidth: 1))

            Text(String(format: "%.1f", value))
                .font(.roadBeansNumeric)
                .foregroundStyle(.primary)
        }
        .frame(width: thumbDiameter, height: thumbDiameter)
        .shadow(color: RoadBeansTheme.Shadow.marker, radius: 6, y: 3)
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                let rawProgress = Double(drag.location.x / max(width, 1))
                let rawValue = rawProgress * (range.upperBound - range.lowerBound) + range.lowerBound
                updateValue(rawValue)
            }
    }

    private func updateValue(_ rawValue: Double) {
        let clamped = BeanSliderModel.clamp(rawValue, range: range)
        let snapped = BeanSliderModel.clamp(BeanSliderModel.snap(clamped, step: step), range: range)

        guard snapped != value else { return }

        let crossedWhole = BeanSliderModel.crossedWholeBoundary(from: value, to: snapped)
        if hapticsEnabled {
            UISelectionFeedbackGenerator().selectionChanged()
            if crossedWhole {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }

        if crossedWhole {
            glyphPulse.toggle()
        }

        value = snapped
    }

    private func adjustAccessibilityValue(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment:
            updateValue(value + step)
        case .decrement:
            updateValue(value - step)
        @unknown default:
            break
        }
    }
}

#Preview {
    @Previewable @State var value = 3.6

    VStack(spacing: 20) {
        BeanSlider(value: $value)
        Text(BeanSliderModel.accessibilityValueText(value))
    }
    .padding()
}
