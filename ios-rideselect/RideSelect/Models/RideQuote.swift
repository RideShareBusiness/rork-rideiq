//
//  RideQuote.swift
//  RideSelect
//

import Foundation

/// A single mock quote for one provider on one route.
nonisolated struct RideQuote: Identifiable, Hashable, Codable {
    let provider: RideProvider
    let price: Double
    let pickupMinutes: Int
    let tripMinutes: Int
    /// Moment the quote was generated; arrival is derived from it.
    let quotedAt: Date

    var id: String { provider.rawValue }

    /// Total door-to-door minutes: waiting for pickup plus the ride itself.
    var totalMinutes: Int { pickupMinutes + tripMinutes }

    var arrival: Date {
        quotedAt.addingTimeInterval(TimeInterval(totalMinutes * 60))
    }

    var formattedPrice: String {
        price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    var formattedArrival: String {
        arrival.formatted(date: .omitted, time: .shortened)
    }
}

/// Badges the recommendation engine can attach to a quote.
nonisolated enum RideBadge: String, Codable, Hashable {
    case bestOverall
    case cheapest
    case fastestPickup
    case fastestArrival

    var title: String {
        switch self {
        case .bestOverall: "Best overall"
        case .cheapest: "Cheapest"
        case .fastestPickup: "Fastest pickup"
        case .fastestArrival: "Fastest arrival"
        }
    }
}

/// A quote plus everything the comparison screen needs to render it.
nonisolated struct RankedQuote: Identifiable, Hashable {
    let quote: RideQuote
    let badges: [RideBadge]
    let isBestOverall: Bool
    /// Plain-English tradeoff line, only present on the recommended ride.
    let explanation: String?

    var id: String { quote.id }

    /// Highest-priority badge to show as the card's pill.
    var primaryBadge: RideBadge? {
        if isBestOverall { return .bestOverall }
        return badges.first { $0 != .bestOverall }
    }
}
