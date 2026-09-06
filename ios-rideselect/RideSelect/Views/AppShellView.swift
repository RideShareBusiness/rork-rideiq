//
//  AppShellView.swift
//  RideSelect
//

import SwiftUI

/// Top-level destinations shown in the floating tab bar.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case compare
    case trips
    case preferences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compare: "Compare"
        case .trips: "Trips"
        case .preferences: "Preferences"
        }
    }

    var symbol: String {
        switch self {
        case .compare: "car.fill"
        case .trips: "clock"
        case .preferences: "person.crop.circle"
        }
    }
}

/// Tab shell shown after a comparison starts. Hosts the custom floating tab bar.
struct AppShellView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedTab: AppTab = .compare
    @State private var preferencesPath: [PreferencesRoute] = []

    private var isTabBarVisible: Bool {
        selectedTab != .preferences || preferencesPath.isEmpty
    }

    var body: some View {
        @Bindable var model = model

        ZStack {
            Palette.canvas.ignoresSafeArea()

            switch selectedTab {
            case .compare:
                CompareView()
            case .trips:
                TripsView()
            case .preferences:
                PreferencesView(path: $preferencesPath)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isTabBarVisible {
                FloatingTabBar(selection: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: isTabBarVisible)
        .sheet(item: $model.bookingCandidate) { quote in
            BookingSheetView(quote: quote)
        }
    }
}

/// Dark capsule tab bar matching the concierge aesthetic.
struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 19, weight: .medium))
                            .symbolVariant(selection == tab ? .fill : .none)
                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selection == tab ? Palette.gold : Palette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.92))
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 6)
        .background(Palette.surface, in: .capsule)
        .overlay { Capsule().stroke(Palette.hairline, lineWidth: 1) }
        .padding(.horizontal, 40)
        .padding(.bottom, 6)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview {
    AppShellView()
        .environment(AppModel())
        .preferredColorScheme(.dark)
}
