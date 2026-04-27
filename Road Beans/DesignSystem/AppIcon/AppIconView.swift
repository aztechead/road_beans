import SwiftUI

struct AppIconView: View {
    enum Variant {
        case light
        case dark
        case tinted
    }

    let variant: Variant

    var body: some View {
        GeometryReader { geometry in
            let canvas = min(geometry.size.width, geometry.size.height)
            let beanWidth = canvas * 0.56

            ZStack {
                background

                AppIconRoastedBean()
                    .fill(beanFill)
                    .overlay(AppIconRoastedBean().stroke(beanOutline, lineWidth: canvas * 0.018))
                    .overlay(alignment: .leading) {
                        AppIconHighlight()
                            .stroke(highlightColor, style: StrokeStyle(lineWidth: canvas * 0.018, lineCap: .round))
                            .padding(.leading, beanWidth * 0.18)
                    }
                    .overlay {
                        AppIconTopoRoad()
                            .stroke(creaseColor, style: StrokeStyle(lineWidth: canvas * 0.008, lineCap: .round, lineJoin: .round))
                            .padding(.horizontal, beanWidth * 0.38)
                            .padding(.vertical, beanWidth * 0.12)
                    }
                    .frame(width: beanWidth, height: beanWidth * 1.28)
                    .rotationEffect(.degrees(-28))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var background: Color {
        switch variant {
        case .light:
            Color(red: 0x2A / 255, green: 0x4A / 255, blue: 0x3A / 255)
        case .dark:
            Color(red: 0x0F / 255, green: 0x0A / 255, blue: 0x07 / 255)
        case .tinted:
            .clear
        }
    }

    private var beanFill: Color {
        switch variant {
        case .light:
            Color(red: 0x9A / 255, green: 0x55 / 255, blue: 0x2E / 255)
        case .dark:
            Color(red: 0xC5 / 255, green: 0xB0 / 255, blue: 0x97 / 255)
        case .tinted:
            .white
        }
    }

    private var beanOutline: Color {
        switch variant {
        case .light:
            Color(red: 0x3B / 255, green: 0x28 / 255, blue: 0x1D / 255)
        case .dark:
            Color(red: 0xFB / 255, green: 0xF7 / 255, blue: 0xEF / 255)
        case .tinted:
            .white
        }
    }

    private var highlightColor: Color {
        switch variant {
        case .light:
            Color(red: 0xE0 / 255, green: 0x86 / 255, blue: 0x54 / 255).opacity(0.75)
        case .dark:
            Color(red: 0xFB / 255, green: 0xF7 / 255, blue: 0xEF / 255).opacity(0.65)
        case .tinted:
            .white
        }
    }

    private var creaseColor: Color {
        switch variant {
        case .light:
            Color(red: 0x1B / 255, green: 0x30 / 255, blue: 0x26 / 255)
        case .dark:
            Color(red: 0xFB / 255, green: 0xF7 / 255, blue: 0xEF / 255)
        case .tinted:
            .white
        }
    }
}

private struct AppIconRoastedBean: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

private struct AppIconHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.22))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.76),
            control1: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.42),
            control2: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.62)
        )
        return path
    }
}

private struct AppIconTopoRoad: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let offsets: [CGFloat] = [-rect.width * 0.018, 0, rect.width * 0.018]

        for offset in offsets {
            let x = rect.midX + offset
            path.move(to: CGPoint(x: x, y: rect.minY + rect.height * 0.18))
            path.addCurve(
                to: CGPoint(x: x, y: rect.maxY - rect.height * 0.18),
                control1: CGPoint(x: x + rect.width * 0.12, y: rect.minY + rect.height * 0.34),
                control2: CGPoint(x: x - rect.width * 0.08, y: rect.minY + rect.height * 0.66)
            )
        }

        return path
    }
}

#Preview {
    AppIconView(variant: .light)
        .frame(width: 256, height: 256)
}

#Preview {
    AppIconView(variant: .dark)
        .frame(width: 256, height: 256)
}
