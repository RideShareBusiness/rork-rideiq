//
//  TripsView.swift
//  RideSelect
//

import SwiftUI

/// History of rides handed off to a provider.
struct TripsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Trips")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Palette.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if model.trips.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No trips yet", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Rides you book through RideSelect will appear here with what you saved.")
        }
        .foregroundStyle(Palette.secondaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(model.trips) { trip in
                    tripCard(trip)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func tripCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ProviderMark(provider: trip.provider, size: 24)
                Text(trip.provider.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.primaryText)
                Spacer(minLength: 0)
                Text(trip.formattedPrice)
                    .font(.system(size: 20, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.primaryText)
            }

            HStack(spacing: 10) {
                Text(trip.pickupName)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.tertiaryText)
                Text(trip.destinationName)
                    .lineLimit(1)
            }
            .font(.system(size: 14))
            .foregroundStyle(Palette.secondaryText)

            HStack(spacing: 8) {
                Text(trip.formattedDate)
                    .font(.caption)
                    .foregroundStyle(Palette.tertiaryText)
                Spacer(minLength: 0)
                if let savedVersus = trip.savedVersus {
                    StatusPill(text: savedVersus, isPrimary: true)
                }
            }
        }
        .padding(18)
        .panel()
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                if let index = model.trips.firstIndex(of: trip) {
                    model.deleteTrips(at: IndexSet(integer: index))
                }
            }
        }
    }
}

#Preview {
    TripsView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
