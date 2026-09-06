//
//  PreferencesView.swift
//  RideSelect
//

import SwiftUI

/// Destinations pushed from the Preferences tab.
enum PreferencesRoute: Hashable {
    case saved
}

/// Primary preference, the Waymo bias, and the personal decision rule.
struct PreferencesView: View {
    @Binding var path: [PreferencesRoute]
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("Preferences")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Palette.primaryText)
                            .padding(.top, 4)

                        section(title: "Primary preference") {
                            VStack(spacing: 0) {
                                ForEach(Array(PrimaryPreference.allCases.enumerated()), id: \.element.id) { index, option in
                                    Button {
                                        withAnimation(.snappy(duration: 0.2)) {
                                            model.preferences.primary = option
                                        }
                                    } label: {
                                        radioRow(title: option.title, isSelected: model.preferences.primary == option)
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.99))

                                    if index < PrimaryPreference.allCases.count - 1 {
                                        Divider().overlay(Palette.hairline).padding(.leading, 62)
                                    }
                                }
                            }
                            .panel()
                        }

                        section(title: "Availability preference") {
                            Toggle("Prefer Waymo when available", isOn: $model.preferences.prefersWaymoWhenAvailable)
                                .tint(Palette.gold)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Palette.primaryText)
                                .padding(.horizontal, 18)
                                .frame(height: 62)
                                .panel(cornerRadius: 20)
                        }

                        section(title: "Decision rule") {
                            decisionRuleCard
                        }

                        section(title: "More") {
                            NavigationLink(value: PreferencesRoute.saved) {
                                HStack(spacing: 14) {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundStyle(Palette.gold)
                                        .frame(width: 24)
                                    Text("Saved preferences")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Palette.primaryText)
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Palette.tertiaryText)
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 62)
                                .panel(cornerRadius: 20)
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.99))
                        }

                        Text("This preference will shape your Best Overall recommendation.")
                            .font(.footnote)
                            .foregroundStyle(Palette.tertiaryText)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(for: PreferencesRoute.self) { route in
                switch route {
                case .saved:
                    SavedPreferencesView()
                }
            }
        }
        .tint(Palette.gold)
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

    private func radioRow(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Palette.gold : Palette.hairline, lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Circle()
                        .fill(Palette.gold)
                        .frame(width: 12, height: 12)
                        .transition(.scale)
                }
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.primaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .contentShape(.rect)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var decisionRuleCard: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: 18) {
            Text("Choose Waymo unless a Black car is within \(priceText) and saves at least \(minutesText).")
                .font(.system(size: 16))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                stepperRow(
                    title: "Price threshold",
                    value: priceText,
                    onDecrement: { adjustPrice(by: -1) },
                    onIncrement: { adjustPrice(by: 1) }
                )
                Divider().overlay(Palette.hairline)
                stepperRow(
                    title: "Time savings threshold",
                    value: minutesText,
                    onDecrement: { adjustMinutes(by: -1) },
                    onIncrement: { adjustMinutes(by: 1) }
                )
            }
            .background(Palette.surfaceRaised, in: .rect(cornerRadius: 18))
        }
        .padding(18)
        .panel()
        .sensoryFeedback(.selection, trigger: model.preferences.priceThreshold)
        .sensoryFeedback(.selection, trigger: model.preferences.timeSavingsThreshold)
    }

    private func stepperRow(
        title: String,
        value: String,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Palette.primaryText)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Palette.gold)
                .contentTransition(.numericText())
            stepperControl(onDecrement: onDecrement, onIncrement: onIncrement)
                .accessibilityLabel(title)
                .accessibilityValue(value)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
    }

    private func stepperControl(
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { onDecrement() }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.primaryText)
                    .frame(width: 46, height: 36)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Decrease")

            Rectangle().fill(Palette.hairline).frame(width: 1, height: 22)

            Button {
                withAnimation(.snappy(duration: 0.2)) { onIncrement() }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.primaryText)
                    .frame(width: 46, height: 36)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Increase")
        }
        .background(Palette.surface, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(Palette.hairline, lineWidth: 1) }
    }

    private var priceText: String {
        model.preferences.priceThreshold.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var minutesText: String {
        "\(model.preferences.timeSavingsThreshold) min"
    }

    private func adjustPrice(by delta: Double) {
        model.preferences.priceThreshold = min(30, max(0, model.preferences.priceThreshold + delta))
    }

    private func adjustMinutes(by delta: Int) {
        model.preferences.timeSavingsThreshold = min(30, max(0, model.preferences.timeSavingsThreshold + delta))
    }
}

#Preview {
    PreferencesView(path: .constant([]))
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
