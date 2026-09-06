//
//  MapBackdropView.swift
//  RideSelect
//

import SwiftUI

/// Faint hand-drawn street grid with a pulsing gold pin, used as home-screen atmosphere.
struct MapBackdropView: View {
    @State private var pulse: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Canvas { context, canvasSize in
                    let stroke = Color(hex: 0x2A2A30)
                    var minor = Path()
                    for index in 0..<7 {
                        let y = canvasSize.height * (0.08 + Double(index) * 0.15)
                        minor.move(to: CGPoint(x: 0, y: y))
                        minor.addCurve(
                            to: CGPoint(x: canvasSize.width, y: y - canvasSize.height * 0.04),
                            control1: CGPoint(x: canvasSize.width * 0.35, y: y + canvasSize.height * 0.03),
                            control2: CGPoint(x: canvasSize.width * 0.62, y: y - canvasSize.height * 0.05)
                        )
                    }
                    for index in 0..<6 {
                        let x = canvasSize.width * (0.1 + Double(index) * 0.18)
                        minor.move(to: CGPoint(x: x, y: 0))
                        minor.addLine(to: CGPoint(x: x - canvasSize.width * 0.06, y: canvasSize.height))
                    }
                    context.stroke(minor, with: .color(stroke.opacity(0.55)), lineWidth: 1)

                    var artery = Path()
                    artery.move(to: CGPoint(x: canvasSize.width * 0.02, y: canvasSize.height * 0.86))
                    artery.addCurve(
                        to: CGPoint(x: canvasSize.width * 0.52, y: canvasSize.height * 0.2),
                        control1: CGPoint(x: canvasSize.width * 0.3, y: canvasSize.height * 0.78),
                        control2: CGPoint(x: canvasSize.width * 0.28, y: canvasSize.height * 0.36)
                    )
                    artery.addCurve(
                        to: CGPoint(x: canvasSize.width * 1.02, y: canvasSize.height * 0.02),
                        control1: CGPoint(x: canvasSize.width * 0.74, y: canvasSize.height * 0.08),
                        control2: CGPoint(x: canvasSize.width * 0.86, y: canvasSize.height * 0.16)
                    )
                    context.stroke(artery, with: .color(stroke), lineWidth: 2.5)
                }

                pin
                    .position(x: size.width * 0.5, y: size.height * 0.62)
            }
            .mask {
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.9), .black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }

    private var pin: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Palette.gold.opacity(0.35 - 0.25 * pulse), lineWidth: 1.5)
                    .frame(width: 28 + 22 * pulse, height: 28 + 22 * pulse)
                Circle()
                    .stroke(Palette.gold, lineWidth: 2)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(Palette.gold)
                    .frame(width: 9, height: 9)
            }
            Rectangle()
                .fill(Palette.gold.opacity(0.7))
                .frame(width: 1.5, height: 22)
            Circle()
                .fill(Palette.gold)
                .frame(width: 6, height: 6)
        }
    }
}

#Preview {
    MapBackdropView()
        .frame(height: 320)
        .background(Palette.canvas)
}
