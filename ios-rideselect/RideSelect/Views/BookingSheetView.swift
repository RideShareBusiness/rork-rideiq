//
//  BookingSheetView.swift
//  RideSelect
//

import SwiftUI

/// Confirms the handoff to a provider app. No booking happens inside RideSelect.
struct BookingSheetView: View {
    let quote: RideQuote

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringProgress: CGFloat = 0
    @State private var didConfirm: Bool = false

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                checkmark
                    .padding(.top, 36)

                Text("Opening \(quote.provider.displayName)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Palette.primaryText)
                    .padding(.top, 28)

                Text("RideSelect will open the provider app to complete your booking.")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 28)

                summary
                    .padding(.top, 28)
                    .padding(.horizontal, 20)

                Button("Continue to \(quote.provider.displayName)") {
                    didConfirm = true
                    model.confirmBooking()
                    dismiss()
                }
                .buttonStyle(IvoryButtonStyle())
                .padding(.top, 26)
                .padding(.horizontal, 20)

                Button("Cancel") {
                    model.cancelBooking()
                    dismiss()
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.gold)
                .padding(.top, 18)

                Spacer(minLength: 12)
            }
        }
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.canvas)
        .sensoryFeedback(.success, trigger: didConfirm)
        .onAppear {
            guard !reduceMotion else {
                ringProgress = 1
                return
            }
            withAnimation(.easeOut(duration: 0.7)) { ringProgress = 1 }
        }
        .onDisappear {
            if !didConfirm { model.cancelBooking() }
        }
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .stroke(Palette.gold.opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Palette.gold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Palette.gold)
                .scaleEffect(ringProgress)
        }
        .frame(width: 116, height: 116)
        .accessibilityHidden(true)
    }

    private var summary: some View {
        VStack(spacing: 0) {
            summaryRow(icon: "tag", label: "Estimated price", value: quote.formattedPrice)
            Divider().overlay(Palette.hairline).padding(.leading, 56)
            summaryRow(icon: "clock", label: "Estimated arrival", value: quote.formattedArrival)
        }
        .panel(cornerRadius: 20)
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Palette.secondaryText)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Palette.primaryText)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.primaryText)
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
    }
}

#Preview {
    BookingSheetView(
        quote: RideQuote(provider: .waymo, price: 34, pickupMinutes: 4, tripMinutes: 18, quotedAt: .now)
    )
    .environment(AppModel())
    .preferredColorScheme(.dark)
}
