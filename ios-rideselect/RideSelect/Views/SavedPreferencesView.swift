//
//  SavedPreferencesView.swift
//  RideSelect
//

import SwiftUI

/// Deeper rider settings that quietly shape every recommendation.
struct SavedPreferencesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        ZStack {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section(title: "Preferred ride provider") {
                        VStack(spacing: 0) {
                            providerRow(nil, title: "No preference")
                            ForEach(Array(RideProvider.allCases.enumerated()), id: \.element.id) { _, provider in
                                Divider().overlay(Palette.hairline).padding(.leading, 62)
                                providerRow(provider, title: provider.displayName)
                            }
                        }
                        .panel()
                    }

                    section(title: "Paying more") {
                        VStack(spacing: 0) {
                            stepperRow(
                                title: "Maximum premium",
                                subtitle: "Most you'll pay over the cheapest ride",
                                value: model.preferences.maxPremium.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                                onDecrement: { model.preferences.maxPremium = max(0, model.preferences.maxPremium - 1) },
                                onIncrement: { model.preferences.maxPremium = min(60, model.preferences.maxPremium + 1) }
                            )
                            Divider().overlay(Palette.hairline)
                            stepperRow(
                                title: "Minimum time savings",
                                subtitle: "Minutes saved needed to justify paying more",
                                value: "\(model.preferences.minTimeSavings) min",
                                onDecrement: { model.preferences.minTimeSavings = max(0, model.preferences.minTimeSavings - 1) },
                                onIncrement: { model.preferences.minTimeSavings = min(45, model.preferences.minTimeSavings + 1) }
                            )
                        }
                        .panel()
                    }

                    section(title: "Driving style") {
                        VStack(spacing: 0) {
                            ForEach(Array(DrivingStylePreference.allCases.enumerated()), id: \.element.id) { index, option in
                                Button {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        model.preferences.drivingStyle = option
                                    }
                                } label: {
                                    selectionRow(
                                        title: option.title,
                                        isSelected: model.preferences.drivingStyle == option
                                    )
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99))

                                if index < DrivingStylePreference.allCases.count - 1 {
                                    Divider().overlay(Palette.hairline).padding(.leading, 18)
                                }
                            }
                        }
                        .panel()
                    }

                    section(title: "Airport rides") {
                        VStack(spacing: 0) {
                            ForEach(Array(AirportPreference.allCases.enumerated()), id: \.element.id) { index, option in
                                Button {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        model.preferences.airportPreference = option
                                    }
                                } label: {
                                    selectionRow(
                                        title: option.title,
                                        isSelected: model.preferences.airportPreference == option
                                    )
                                }
                                .buttonStyle(PressableButtonStyle(scale: 0.99))

                                if index < AirportPreference.allCases.count - 1 {
                                    Divider().overlay(Palette.hairline).padding(.leading, 18)
                                }
                            }
                        }
                        .panel()

                        Text("Applied automatically when your pickup or destination is an airport.")
                            .font(.footnote)
                            .foregroundStyle(Palette.tertiaryText)
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Saved preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.canvas, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Pieces

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .metricLabel()
                .padding(.leading, 4)
            content()
        }
    }

    private func providerRow(_ provider: RideProvider?, title: String) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                model.preferences.preferredProvider = provider
            }
        } label: {
            HStack(spacing: 16) {
                Group {
                    if let provider {
                        ProviderMark(provider: provider, size: 22)
                    } else {
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(Palette.tertiaryText)
                            .frame(width: 28)
                    }
                }
                .frame(width: 34, alignment: .leading)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                Spacer(minLength: 0)
                if model.preferences.preferredProvider == provider {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.gold)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 60)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99))
        .accessibilityAddTraits(model.preferences.preferredProvider == provider ? [.isButton, .isSelected] : .isButton)
    }

    private func selectionRow(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.primaryText)
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.gold)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .contentShape(.rect)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func stepperRow(
        title: String,
        subtitle: String,
        value: String,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 8) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.gold)
                    .contentTransition(.numericText())
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.snappy(duration: 0.2)) { onDecrement() }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.primaryText)
                            .frame(width: 44, height: 34)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Decrease \(title)")

                    Rectangle().fill(Palette.hairline).frame(width: 1, height: 20)

                    Button {
                        withAnimation(.snappy(duration: 0.2)) { onIncrement() }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.primaryText)
                            .frame(width: 44, height: 34)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Increase \(title)")
                }
                .background(Palette.surfaceRaised, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Palette.hairline, lineWidth: 1) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .accessibilityElement(children: .contain)
        .accessibilityValue(value)
    }
}

#Preview {
    NavigationStack {
        SavedPreferencesView()
            .environment(AppModel())
    }
    .preferredColorScheme(.dark)
}
