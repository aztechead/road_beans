import SwiftUI

struct Icon: View {
    enum Kind {
        case drink(DrinkCategory)
        case place(PlaceKind)
        case taste(TasteAxis)
    }

    let kind: Kind
    var size: CGFloat = 24
    var active = false

    init(_ kind: Kind, size: CGFloat = 24, active: Bool = false) {
        self.kind = kind
        self.size = size
        self.active = active
    }

    private var color: Color {
        active ? .accent(.on) : .ink(.secondary)
    }

    private var lineWidth: CGFloat {
        max(size / 24 * 1.5, 0.75)
    }

    var body: some View {
        Group {
            switch kind {
            case .drink(let category):
                DrinkIcon(category: category)
                    .stroke(color, style: strokeStyle)
            case .place(let kind):
                PlaceKindIcon(kind: kind)
                    .stroke(color, style: strokeStyle)
            case .taste(let axis):
                TasteProfileIcon(axis: axis)
                    .stroke(color, style: strokeStyle)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    }
}
