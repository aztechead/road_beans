import SwiftUI

struct BeanRating: View {
    let value: Double
    var pixelSize: CGFloat = 3

    var body: some View {
        HStack(spacing: 8) {
            BeanGlyph(beanCount: BeanGlyph.beanCount(for: value), pixelSize: pixelSize)

            Text(String(format: "%.1f", value))
                .font(.roadBeansNumeric)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Average rating")
        .accessibilityValue(BeanSliderModel.accessibilityValueText(value))
    }
}

#Preview {
    BeanRating(value: 3.6)
        .padding()
}
