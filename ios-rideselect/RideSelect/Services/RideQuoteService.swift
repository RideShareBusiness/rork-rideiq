//
//  RideQuoteService.swift
//  RideSelect
//

import Foundation

/// Deterministic pseudo-random generator so a route always quotes the same numbers.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Produces realistic mock pricing and wait times. No provider APIs are contacted.
nonisolated enum RideQuoteService {
    /// Quotes all three premium options for a route.
    /// - Parameter variation: bumps the seed so a manual refresh nudges the numbers.
    static func quotes(for route: RideRoute, at date: Date = .now, variation: Int = 0) -> [RideQuote] {
        // The showcase route keeps the exact numbers used throughout the concept.
        if variation == 0, route.destination.name == "425 Market St" {
            return [
                RideQuote(provider: .waymo, price: 34, pickupMinutes: 4, tripMinutes: 18, quotedAt: date),
                RideQuote(provider: .uberBlack, price: 42, pickupMinutes: 3, tripMinutes: 17, quotedAt: date),
                RideQuote(provider: .lyftBlack, price: 39, pickupMinutes: 7, tripMinutes: 18, quotedAt: date)
            ]
        }

        // Real trip distance from the resolved coordinates, with a hint as fallback.
        let miles = max(1.5, route.distanceMiles ?? route.destination.distanceHint)
        var generator = SeededGenerator(seed: seed(for: route, variation: variation))

        return RideProvider.allCases.map { provider in
            let jitter = Double(Int.random(in: -12...12, using: &generator)) / 100.0
            let pickupJitter = Int.random(in: -2...3, using: &generator)
            let tripJitter = Int.random(in: -2...3, using: &generator)

            let baseTrip = Int((miles * 2.4).rounded()) + 4
            let tripMinutes = max(6, baseTrip + tripJitter + provider.tripOffset)
            let pickupMinutes = max(2, provider.basePickup + pickupJitter)
            let price = (provider.baseFare + miles * provider.perMile) * (1 + jitter)

            return RideQuote(
                provider: provider,
                price: (price / 1).rounded(),
                pickupMinutes: pickupMinutes,
                tripMinutes: tripMinutes,
                quotedAt: date
            )
        }
    }

    private static func seed(for route: RideRoute, variation: Int) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(route.pickup.name)
        hasher.combine(route.destination.name)
        hasher.combine(variation)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }
}

private nonisolated extension RideProvider {
    var baseFare: Double {
        switch self {
        case .waymo: 12.5
        case .uberBlack: 19.0
        case .lyftBlack: 16.5
        }
    }

    var perMile: Double {
        switch self {
        case .waymo: 4.9
        case .uberBlack: 5.6
        case .lyftBlack: 5.2
        }
    }

    var basePickup: Int {
        switch self {
        case .waymo: 5
        case .uberBlack: 4
        case .lyftBlack: 6
        }
    }

    /// Waymo drives conservatively; black cars shave a minute in traffic.
    var tripOffset: Int {
        switch self {
        case .waymo: 1
        case .uberBlack: -1
        case .lyftBlack: 0
        }
    }
}
