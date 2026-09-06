//
//  RideQuoteCard.swift
//  RideSelect
//

import SwiftUI

/// Metric-forward ride card: provider header, four scannable metrics, and a book action.
struct RideQuoteCard: View {
    let ranked: RankedQuote
    let onBook: () -> Void

    private var quote: RideQuote { ranked.quote }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let badge = ranked.primaryBadge {
                StatusPill(text: badge.title, isPrimary: ranked.isBestOverall)
            }

            HStack(spacing: 12) {
                ProviderMark(provider: quote.provider)
                Text(quote.provider.displayName)
                    .font(.system(size: 21, weight: .bold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.primaryText)
                Spacer(minLength: 0)
                Text(quote.provider.rideType)
                    .font(.caption)
                    .foregroundStyle(Palette.tertiaryText)
            }

            metrics

            if let explanation = ranked.explanation {
                Text(explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Book \(quote.provider.displayName)", action: onBook)
                .buttonStyle(IvoryButtonStyle())
        }
        .padding(20)
        .panel(isHighlighted: ranked.isBestOverall)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }

    private var metrics: some View {
        HStack(alignment: .top, spacing: 0) {
            metric(label: "Price", value: quote.formattedPrice, isEmphasized: true)
            divider
            metric(label: "Pickup", value: "\(quote.pickupMinutes)", unit: "min")
            divider
            metric(label: "Trip", value: "\(quote.tripMinutes)", unit: "min")
            divider
            metric(label: "Arrival", value: arrivalValue, unit: arrivalUnit)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 44)
    }

    private var arrivalValue: String {
        quote.formattedArrival
            .replacingOccurrences(of: " AM", with: "")
            .replacingOccurrences(of: " PM", with: "")
    }

    private var arrivalUnit: String {
        quote.formattedArrival.contains("AM") ? "AM" : "PM"
    }

    private func metric(label: String, value: String, unit: String? = nil, isEmphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .metricLabel()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: isEmphasized ? 30 : 24, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(isEmphasized && ranked.isBestOverall ? Palette.gold : Palette.primaryText)
                if let unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
    }

    private var accessibilitySummary: String {
        var parts: [String] = [quote.provider.displayName]
        if ranked.isBestOverall { parts.append("Best overall") }
        parts.append("\(quote.formattedPrice), pickup in \(quote.pickupMinutes) minutes, \(quote.tripMinutes) minute trip, arriving \(quote.formattedArrival)")
        if let explanation = ranked.explanation { parts.append(explanation) }
        return parts.joined(separator: ". ")
    }
}

#Preview {
    let quote = RideQuote(provider: .waymo, price: 34, pickupMinutes: 4, tripMinutes: 18, quotedAt: .now)
    return RideQuoteCard(
        ranked: RankedQuote(
            quote: quote,
            badges: [.cheapest],
            isBestOverall: true,
            explanation: "Save $8 vs Uber Black and arrive only 2 minutes later."
        ),
        onBook: {}
    )
    .padding(20)
    .background(Palette.canvas)
}
