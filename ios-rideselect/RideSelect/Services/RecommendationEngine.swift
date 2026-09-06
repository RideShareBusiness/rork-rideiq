//
//  RecommendationEngine.swift
//  RideSelect
//

import Foundation

/// Turns raw quotes plus rider preferences into a ranked list with a single
/// clearly explained Best Overall recommendation.
nonisolated enum RecommendationEngine {

    static func rank(
        quotes: [RideQuote],
        preferences: RidePreferences,
        isAirportTrip: Bool
    ) -> [RankedQuote] {
        guard !quotes.isEmpty else { return [] }

        var settings = preferences
        settings.isAirportTrip = isAirportTrip

        let cheapest = quotes.min { $0.price < $1.price }
        let fastestPickup = quotes.min { $0.pickupMinutes < $1.pickupMinutes }
        let fastestArrival = quotes.min { $0.totalMinutes < $1.totalMinutes }
        let best = bestOverall(quotes: quotes, preferences: settings)

        let ordered = sort(quotes: quotes, preferences: settings, best: best)

        return ordered.map { quote in
            var badges: [RideBadge] = []
            if quote.id == cheapest?.id { badges.append(.cheapest) }
            if quote.id == fastestPickup?.id { badges.append(.fastestPickup) }
            if quote.id == fastestArrival?.id { badges.append(.fastestArrival) }

            let isBest = quote.id == best.id
            return RankedQuote(
                quote: quote,
                badges: badges,
                isBestOverall: isBest,
                explanation: isBest ? explanation(for: quote, among: quotes, preferences: settings) : nil
            )
        }
    }

    // MARK: - Ordering

    private static func sort(
        quotes: [RideQuote],
        preferences: RidePreferences,
        best: RideQuote
    ) -> [RideQuote] {
        let rest = quotes.filter { $0.id != best.id }
        let sortedRest: [RideQuote]

        switch preferences.effectivePrimary {
        case .lowestPrice:
            sortedRest = rest.sorted { $0.price < $1.price }
        case .fastestPickup:
            sortedRest = rest.sorted { $0.pickupMinutes < $1.pickupMinutes }
        case .fastestArrival:
            sortedRest = rest.sorted { $0.totalMinutes < $1.totalMinutes }
        case .bestOverall:
            sortedRest = rest.sorted { score($0, in: quotes, preferences: preferences) > score($1, in: quotes, preferences: preferences) }
        }

        return [best] + sortedRest
    }

    // MARK: - Best overall

    private static func bestOverall(quotes: [RideQuote], preferences: RidePreferences) -> RideQuote {
        switch preferences.effectivePrimary {
        case .lowestPrice:
            return quotes.min { $0.price < $1.price } ?? quotes[0]
        case .fastestPickup:
            return quotes.min { $0.pickupMinutes < $1.pickupMinutes } ?? quotes[0]
        case .fastestArrival:
            return quotes.min { $0.totalMinutes < $1.totalMinutes } ?? quotes[0]
        case .bestOverall:
            break
        }

        let scored = quotes.max { score($0, in: quotes, preferences: preferences) < score($1, in: quotes, preferences: preferences) }
        var winner = scored ?? quotes[0]

        // Personal decision rule: stay with Waymo unless a black car is close on
        // price AND meaningfully faster door to door.
        if preferences.prefersWaymoWhenAvailable, let waymo = quotes.first(where: { $0.provider == .waymo }) {
            let challengers = quotes.filter { $0.provider.isBlackCar }
            let beatsRule = challengers.contains { challenger in
                let extraCost = challenger.price - waymo.price
                let minutesSaved = waymo.totalMinutes - challenger.totalMinutes
                return extraCost <= preferences.priceThreshold
                    && minutesSaved >= preferences.timeSavingsThreshold
            }
            winner = beatsRule ? (bestChallenger(quotes: quotes, preferences: preferences) ?? winner) : waymo
        }

        // Airport runs with luggage lean toward a human driver.
        if preferences.isAirportTrip,
           preferences.airportPreference == .humanDriverWithLuggage,
           winner.provider.isAutonomous,
           let humanDriven = quotes.filter({ $0.provider.isBlackCar }).min(by: { $0.totalMinutes < $1.totalMinutes }) {
            winner = humanDriven
        }

        // Never recommend paying more than the rider's stated premium ceiling
        // unless the time saved clears their minimum.
        if let cheapest = quotes.min(by: { $0.price < $1.price }), winner.id != cheapest.id {
            let premium = winner.price - cheapest.price
            let minutesSaved = cheapest.totalMinutes - winner.totalMinutes
            if premium > preferences.maxPremium || minutesSaved < preferences.minTimeSavings {
                winner = cheapest
            }
        }

        return winner
    }

    /// The strongest black car alternative when the decision rule is triggered.
    private static func bestChallenger(quotes: [RideQuote], preferences: RidePreferences) -> RideQuote? {
        quotes
            .filter { $0.provider.isBlackCar }
            .max { score($0, in: quotes, preferences: preferences) < score($1, in: quotes, preferences: preferences) }
    }

    // MARK: - Scoring

    /// Normalized 0…1 blend of price and door-to-door time, nudged by rider biases.
    private static func score(_ quote: RideQuote, in quotes: [RideQuote], preferences: RidePreferences) -> Double {
        let prices = quotes.map(\.price)
        let totals = quotes.map { Double($0.totalMinutes) }

        let priceScore = normalized(quote.price, min: prices.min() ?? 0, max: prices.max() ?? 1)
        let timeScore = normalized(Double(quote.totalMinutes), min: totals.min() ?? 0, max: totals.max() ?? 1)
        let pickupScore = normalized(
            Double(quote.pickupMinutes),
            min: Double(quotes.map(\.pickupMinutes).min() ?? 0),
            max: Double(quotes.map(\.pickupMinutes).max() ?? 1)
        )

        var total = priceScore * 0.5 + timeScore * 0.35 + pickupScore * 0.15

        switch preferences.drivingStyle {
        case .autonomous where quote.provider.isAutonomous: total += 0.08
        case .humanDriver where quote.provider.isBlackCar: total += 0.08
        default: break
        }

        if let preferred = preferences.preferredProvider, preferred == quote.provider {
            total += 0.1
        }

        return total
    }

    /// 1 is best (lowest value), 0 is worst.
    private static func normalized(_ value: Double, min lower: Double, max upper: Double) -> Double {
        guard upper > lower else { return 1 }
        return 1 - ((value - lower) / (upper - lower))
    }

    // MARK: - Explanation

    /// One plain-English sentence that makes the tradeoff obvious without math.
    private static func explanation(
        for winner: RideQuote,
        among quotes: [RideQuote],
        preferences: RidePreferences
    ) -> String {
        let others = quotes.filter { $0.id != winner.id }
        guard !others.isEmpty else { return "The only premium ride available right now." }

        let priciest = others.max { $0.price < $1.price }
        let quickest = others.min { $0.totalMinutes < $1.totalMinutes }

        if let rival = priciest, rival.price > winner.price {
            let saving = Int((rival.price - winner.price).rounded())
            let minutesLater = winner.totalMinutes - rival.totalMinutes
            if saving >= 3, minutesLater > 0 {
                let plural = minutesLater == 1 ? "minute" : "minutes"
                return "Save $\(saving) vs \(rival.provider.displayName) and arrive only \(minutesLater) \(plural) later."
            }
            if saving >= 3, minutesLater <= 0 {
                return "Save $\(saving) vs \(rival.provider.displayName) and still arrive first."
            }
        }

        if let rival = quickest, winner.totalMinutes < rival.totalMinutes {
            let minutesFaster = rival.totalMinutes - winner.totalMinutes
            let extra = Int((winner.price - rival.price).rounded())
            if extra > 0 {
                return "\(winner.provider.displayName) gets you there \(minutesFaster) minutes faster for $\(extra) more."
            }
            return "\(winner.provider.displayName) is both the fastest and the best value right now."
        }

        if winner.pickupMinutes <= (others.map(\.pickupMinutes).min() ?? winner.pickupMinutes) {
            return "\(winner.provider.displayName) reaches you fastest with the strongest overall value."
        }

        switch preferences.effectivePrimary {
        case .lowestPrice:
            return "Lowest price for this route, matching your preference."
        case .fastestPickup:
            return "Shortest wait for pickup, matching your preference."
        case .fastestArrival:
            return "Earliest arrival for this route, matching your preference."
        case .bestOverall:
            return "\(winner.provider.displayName) offers the best combination of price and arrival time."
        }
    }
}
