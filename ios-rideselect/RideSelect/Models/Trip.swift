//
//  Trip.swift
//  RideSelect
//

import Foundation

/// A booking handed off to a provider, kept in the Trips tab.
nonisolated struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    let provider: RideProvider
    let pickupName: String
    let destinationName: String
    let price: Double
    let pickupMinutes: Int
    let tripMinutes: Int
    let bookedAt: Date
    /// Dollars saved versus the most expensive alternative, if any.
    let savedVersus: String?

    init(
        id: UUID = UUID(),
        provider: RideProvider,
        pickupName: String,
        destinationName: String,
        price: Double,
        pickupMinutes: Int,
        tripMinutes: Int,
        bookedAt: Date = .now,
        savedVersus: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.pickupName = pickupName
        self.destinationName = destinationName
        self.price = price
        self.pickupMinutes = pickupMinutes
        self.tripMinutes = tripMinutes
        self.bookedAt = bookedAt
        self.savedVersus = savedVersus
    }

    var formattedPrice: String {
        price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    var formattedDate: String {
        bookedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
