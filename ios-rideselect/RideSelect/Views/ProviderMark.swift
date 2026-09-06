//
//  ProviderMark.swift
//  RideSelect
//

import SwiftUI

/// Compact monochrome mark that identifies a provider on a ride card.
struct ProviderMark: View {
    let provider: RideProvider
    var size: CGFloat = 30

    var body: some View {
        Group {
            switch provider {
            case .waymo:
                WaymoGlyph()
                    .stroke(Palette.primaryText, style: StrokeStyle(lineWidth: size * 0.14, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 1.15, height: size * 0.58)
            case .uberBlack:
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(Palette.primaryText)
                    .frame(width: size, height: size)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.08)
                            .fill(Palette.canvas)
                            .frame(width: size * 0.34, height: size * 0.34)
                    }
            case .lyftBlack:
                Text("lyft")
                    .font(.system(size: size * 0.82, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
                    .kerning(-1)
            }
        }
        .frame(width: size * 1.3, height: size, alignment: .leading)
        .accessibilityHidden(true)
    }
}

/// A stylized double-V wordmark stand-in for Waymo.
private struct WaymoGlyph: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 4
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + step * 0.85, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + step * 2, y: rect.minY + rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.minX + step * 3.15, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach(RideProvider.allCases) { provider in
            ProviderMark(provider: provider)
        }
    }
    .padding(40)
    .background(Palette.canvas)
}
