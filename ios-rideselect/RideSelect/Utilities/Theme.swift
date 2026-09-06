//
//  Theme.swift
//  RideSelect
//

import SwiftUI

/// Central design tokens for the RideSelect dark, black-car luxury aesthetic.
nonisolated enum Palette {
    static let canvas = Color(hex: 0x0A0A0C)
    static let surface = Color(hex: 0x151518)
    static let surfaceRaised = Color(hex: 0x1C1C20)
    static let hairline = Color(hex: 0x232327)
    static let primaryText = Color(hex: 0xEDEDEF)
    static let secondaryText = Color(hex: 0x8B8B90)
    static let tertiaryText = Color(hex: 0x5C5C63)
    static let gold = Color(hex: 0xC9A24B)
    static let goldBright = Color(hex: 0xE3BE6A)
    static let ivory = Color(hex: 0xEDEDEF)
}

nonisolated extension Color {
    /// Creates a color from a 0xRRGGBB literal.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}

/// Small uppercase, letter-spaced label used above every metric value.
struct MetricLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Palette.secondaryText)
    }
}

/// Card container shared by ride cards, input groups, and preference sections.
struct PanelStyle: ViewModifier {
    var cornerRadius: CGFloat = 24
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(Palette.surface, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isHighlighted ? Palette.gold.opacity(0.75) : Palette.hairline,
                        lineWidth: isHighlighted ? 1.5 : 1
                    )
            }
    }
}

extension View {
    func metricLabel() -> some View { modifier(MetricLabelStyle()) }

    func panel(cornerRadius: CGFloat = 24, isHighlighted: Bool = false) -> some View {
        modifier(PanelStyle(cornerRadius: cornerRadius, isHighlighted: isHighlighted))
    }
}

/// Full-width ivory pill button used for every primary action.
struct IvoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.canvas)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Palette.ivory.opacity(configuration.isPressed ? 0.82 : 1), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Subtle press feedback for cards, chips, and quiet controls.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

/// Gold or neutral status pill (BEST OVERALL, CHEAPEST, ...).
struct StatusPill: View {
    let text: String
    var isPrimary: Bool = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(isPrimary ? Palette.goldBright : Palette.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isPrimary ? Palette.gold.opacity(0.14) : Palette.surfaceRaised,
                in: .capsule
            )
            .overlay {
                Capsule()
                    .stroke(isPrimary ? Palette.gold.opacity(0.5) : Palette.hairline, lineWidth: 1)
            }
    }
}
