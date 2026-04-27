// Road Beans/DesignSystem/Tokens/RoadBeansColor.swift
//
// Primitive ramps (reference only — never import directly from feature code):
//
// Forest: #2A4A3A (core), #1B3026 (dark), #6F9883 (lifted)
// Roast:  100=#F0E5D2  200=#E8DCC9  300=#C5B097  500=#8A6D55  700=#5C4434  800=#3B281D  900=#1F1410
// Cream:  #FBF7EF → #F8F1E4 → #EFE5D2 → #E2D4BB
// Espresso: #0F0A07 → #181210 → #221814
// Ember:  light=#C66A35  dark=#E08654
//
import SwiftUI

enum RoadBeansColor {
    enum Surface: String, CaseIterable {
        case canvas, raised, sunken
        var assetName: String { "Surface\(rawValue.capitalized)" }
        var color: Color { Color(assetName, bundle: .main) }
    }

    enum Ink: String, CaseIterable {
        case primary, secondary, tertiary
        var assetName: String { "Ink\(rawValue.capitalized)" }
        var color: Color { Color(assetName, bundle: .main) }
    }

    enum Divider: String, CaseIterable {
        case hairline, strong
        var assetName: String { "Divider\(rawValue.capitalized)" }
        var color: Color { Color(assetName, bundle: .main) }
    }

    enum Accent: String, CaseIterable {
        case `default`, pressed, on
        var assetName: String {
            switch self {
            case .default: return "AccentDefault"
            case .pressed: return "AccentPressed"
            case .on:      return "AccentOn"
            }
        }
        var color: Color { Color(assetName, bundle: .main) }
    }

    enum State: String, CaseIterable {
        case success, warning, danger
        var assetName: String { "State\(rawValue.capitalized)" }
        var color: Color { Color(assetName, bundle: .main) }
    }
}

extension Color {
    static func surface(_ token: RoadBeansColor.Surface) -> Color { token.color }
    static func ink(_ token: RoadBeansColor.Ink) -> Color { token.color }
    static func divider(_ token: RoadBeansColor.Divider) -> Color { token.color }
    static func accent(_ token: RoadBeansColor.Accent) -> Color { token.color }
    static func state(_ token: RoadBeansColor.State) -> Color { token.color }
}

extension ShapeStyle where Self == Color {
    static func surface(_ token: RoadBeansColor.Surface) -> Color { token.color }
    static func ink(_ token: RoadBeansColor.Ink) -> Color { token.color }
    static func divider(_ token: RoadBeansColor.Divider) -> Color { token.color }
    static func accent(_ token: RoadBeansColor.Accent) -> Color { token.color }
    static func state(_ token: RoadBeansColor.State) -> Color { token.color }
}
