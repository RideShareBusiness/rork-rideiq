//
//  CompareView.swift
//  RideSelect
//

import SwiftUI

/// The comparison tab: route header, ranking filters, and the three premium ride cards.
struct CompareView: View {
    @Environment(AppModel.self) private var model
    @State private var appearedCards: Bool = false

    var body: some View {
        @Bindable var model = model

        ZStack {
            Palette.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                routeHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                filterChips
                    .padding(.top, 16)

                if model.isSearching {
                    ScanningView()
                        .transition(.opacity)
                } else {
                    results
                        .transition(.opacity)
                }
            }
        }
        .animation(.snappy(duration: 0.3), value: model.isSearching)
    }

    // MARK: - Header

    private var routeHeader: some View {
        Button {
            model.returnHome()
        } label: {
            HStack(spacing: 14) {
                Text(model.route.pickup.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.tertiaryText)
                Text(model.route.destination.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .frame(height: 44)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99))
        .accessibilityLabel("Route from \(model.route.pickup.name) to \(model.route.destination.name). Edit route.")
    }

    // MARK: - Filters

    private var filterChips: some View {
        @Bindable var model = model

        return ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(PrimaryPreference.allCases) { option in
                    let isSelected = model.preferences.primary == option
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            model.preferences.primary = option
                        }
                    } label: {
                        Text(option.filterTitle)
                            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Palette.goldBright : Palette.secondaryText)
                            .padding(.horizontal, 18)
                            .frame(height: 40)
                            .background(
                                isSelected ? Palette.gold.opacity(0.12) : .clear,
                                in: .capsule
                            )
                            .overlay {
                                if isSelected {
                                    Capsule().stroke(Palette.gold.opacity(0.5), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.95))
                }
            }
            .padding(.vertical, 5)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(Palette.surface)
                .overlay { RoundedRectangle(cornerRadius: 26).stroke(Palette.hairline, lineWidth: 1) }
                .padding(.horizontal, 20)
        }
        .sensoryFeedback(.selection, trigger: model.preferences.primary)
    }

    // MARK: - Results

    private var results: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(model.rankedQuotes.enumerated()), id: \.element.id) { index, ranked in
                    RideQuoteCard(ranked: ranked) {
                        model.startBooking(for: ranked.quote)
                    }
                    .opacity(appearedCards ? 1 : 0)
                    .offset(y: appearedCards ? 0 : 18)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.88).delay(Double(index) * 0.07),
                        value: appearedCards
                    )
                }

                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            model.refreshQuotes(nudge: true)
        }
        .onAppear { appearedCards = true }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Text("Estimates only. RideSelect hands off to the provider app to complete booking.")
                .font(.caption)
                .foregroundStyle(Palette.tertiaryText)
                .multilineTextAlignment(.center)
            Text("Updated \(model.lastUpdated.formatted(date: .omitted, time: .shortened)) · Pull to refresh")
                .font(.caption2)
                .foregroundStyle(Palette.tertiaryText)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }
}

#Preview {
    CompareView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
