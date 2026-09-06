//
//  RidePreferences.swift
//  RideSelect
//

import Foundation

/// How the comparison list is ranked and which ride earns the Best Overall badge.
nonisolated enum PrimaryPreference: String, CaseIterable, Codable, Identifiable, Hashable {
    case bestOverall
    case lowestPrice
    case fastestPickup
    case fastestArrival

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bestOverall: "Best overall"
        case .lowestPrice: "Lowest price"
        case .fastestPickup: "Fastest pickup"
        case .fastestArrival: "Fastest arrival"
        }
    }

    /// Shorter label used by the filter chips on the comparison screen.
    var filterTitle: String {
        switch self {
        case .bestOverall: "Best Overall"
        case .lowestPrice: "Lowest Price"
        case .fastestPickup: "Fastest Pickup"
        case .fastestArrival: "Fastest Arrival"
        }
    }
}

/// Whether the rider leans toward driverless or human-driven cars.
nonisolated enum DrivingStylePreference: String, CaseIterable, Codable, Identifiable, Hashable {
    case noPreference
    case autonomous
    case humanDriver

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noPreference: "No preference"
        case .autonomous: "Prefer autonomous"
        case .humanDriver: "Prefer human driver"
        }
    }
}

/// What matters most on airport runs, where luggage and flight times change the math.
nonisolated enum AirportPreference: String, CaseIterable, Codable, Identifiable, Hashable {
    case sameAsUsual
    case fastestArrival
    case humanDriverWithLuggage
    case lowestPrice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameAsUsual: "Same as usual"
        case .fastestArrival: "Always fastest arrival"
        case .humanDriverWithLuggage: "Human driver for luggage"
        case .lowestPrice: "Always lowest price"
        }
    }
}

/// All rider settings that shape the recommendation. Persisted as JSON in `UserDefaults`.
nonisolated struct RidePreferences: Codable, Equatable {
    var primary: PrimaryPreference = .bestOverall
    var prefersWaymoWhenAvailable: Bool = true

    /// Decision rule: choose Waymo unless a black car is within this many dollars…
    var priceThreshold: Double = 5
    /// …and saves at least this many minutes.
    var timeSavingsThreshold: Int = 5

    // Saved preferences
    var preferredProvider: RideProvider?
    /// Maximum extra dollars the rider will pay over the cheapest option.
    var maxPremium: Double = 12
    /// Minimum minutes saved required to justify paying more.
    var minTimeSavings: Int = 4
    var drivingStyle: DrivingStylePreference = .autonomous
    var airportPreference: AirportPreference = .sameAsUsual
    /// When true, the current route is treated as an airport run.
    var isAirportTrip: Bool = false

    static let `default` = RidePreferences()

    /// The primary preference actually in force, accounting for airport overrides.
    var effectivePrimary: PrimaryPreference {
        guard isAirportTrip else { return primary }
        switch airportPreference {
        case .sameAsUsual: return primary
        case .fastestArrival: return .fastestArrival
        case .lowestPrice: return .lowestPrice
        case .humanDriverWithLuggage: return primary
        }
    }
}
