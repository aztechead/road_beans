import SwiftUI

struct TopoShape: Shape {
    let seed: UInt64
    let ringCount: Int
    let amplitude: CGFloat
    let frequency: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var rng = SplitMix64(state: seed)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) * 0.5
        let count = min(max(ringCount, 1), 12)

        for ring in 0..<count {
            let ringFraction = CGFloat(ring + 1) / CGFloat(count + 1)
            let baseRingRadius = baseRadius * ringFraction
            let phaseShift = CGFloat(rng.nextDouble()) * .pi * 2
            let localAmplitude = baseRadius * amplitude * (0.6 + CGFloat(rng.nextDouble()) * 0.8)
            let segments = 64

            for segment in 0...segments {
                let theta = CGFloat(segment) / CGFloat(segments) * .pi * 2
                let perturbation = sin(theta * frequency + phaseShift) * localAmplitude
                let radius = baseRingRadius + perturbation
                let point = CGPoint(
                    x: center.x + cos(theta) * radius,
                    y: center.y + sin(theta) * radius
                )

                if segment == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            path.closeSubpath()
        }

        return path
    }
}

struct SplitMix64 {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}

#Preview {
    HStack(spacing: RoadBeansSpacing.lg) {
        TopoShape(seed: TopoSeeds.onboarding, ringCount: 5, amplitude: 0.18, frequency: 4)
            .stroke(Color.accent(.default).opacity(0.4), lineWidth: 1)
        TopoShape(seed: TopoSeeds.emptyState, ringCount: 7, amplitude: 0.10, frequency: 5)
            .stroke(Color.accent(.default).opacity(0.4), lineWidth: 1)
    }
    .frame(height: 240)
    .padding()
    .background(Color.surface(.canvas))
}
