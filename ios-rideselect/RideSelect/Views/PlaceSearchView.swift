//
//  PlaceSearchView.swift
//  RideSelect
//

import SwiftUI

/// Sheet for choosing a pickup or destination via Google Places autocomplete.
struct PlaceSearchView: View {
    enum Target: String, Identifiable {
        case pickup
        case destination

        var id: String { rawValue }

        var title: String {
            switch self {
            case .pickup: "Pickup"
            case .destination: "Destination"
            }
        }

        var prompt: String {
            switch self {
            case .pickup: "Search pickup"
            case .destination: "Where to?"
            }
        }
    }

    /// What the results area is currently showing.
    private enum ResultState: Equatable {
        case idle
        case loading
        case results([PlaceSuggestion])
        case empty
        case failed(String)
    }

    let target: Target

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var state: ResultState = .idle
    /// Groups keystrokes and the follow-up details call into one billable session.
    @State private var sessionToken: String = UUID().uuidString
    @State private var resolvingPlaceID: String?
    @State private var isLocating: Bool = false
    @FocusState private var isFieldFocused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showsCurrentLocationRow: Bool {
        target == .pickup && trimmedQuery.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.canvas.ignoresSafeArea()

                VStack(spacing: 18) {
                    searchField

                    ScrollView {
                        VStack(spacing: 14) {
                            if showsCurrentLocationRow {
                                currentLocationCard
                            }
                            resultsContent
                            attribution
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle(target.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.canvas, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Palette.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { isFieldFocused = true }
        .task(id: query) {
            await runDebouncedSearch()
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.gold)
            TextField("", text: $query, prompt: Text(target.prompt).foregroundStyle(Palette.tertiaryText))
                .focused($isFieldFocused)
                .foregroundStyle(Palette.primaryText)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
            if case .loading = state {
                ProgressView()
                    .controlSize(.small)
                    .tint(Palette.tertiaryText)
            } else if !query.isEmpty {
                Button {
                    query = ""
                    state = .idle
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.tertiaryText)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .panel(cornerRadius: 18)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        switch state {
        case .idle:
            if !showsCurrentLocationRow {
                hintCard
            }
        case .loading:
            if case .loading = state, !showsCurrentLocationRow {
                loadingCard
            }
        case .results(let suggestions):
            suggestionList(suggestions)
        case .empty:
            messageCard(
                icon: "mappin.slash",
                title: "No results",
                message: "Nothing matched “\(trimmedQuery)”. Try a different address or place name."
            )
        case .failed(let message):
            messageCard(
                icon: "exclamationmark.triangle",
                title: "Search unavailable",
                message: message,
                retry: trimmedQuery.isEmpty ? nil : { Task { await runSearch(trimmedQuery) } }
            )
        }
    }

    private func suggestionList(_ suggestions: [PlaceSuggestion]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button {
                    select(suggestion)
                } label: {
                    suggestionRow(suggestion)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.99))
                .disabled(resolvingPlaceID != nil)

                if index < suggestions.count - 1 {
                    Divider()
                        .overlay(Palette.hairline)
                        .padding(.leading, 60)
                }
            }
        }
        .panel()
    }

    private func suggestionRow(_ suggestion: PlaceSuggestion) -> some View {
        HStack(spacing: 16) {
            Image(systemName: suggestion.isAirport ? "airplane" : "mappin")
                .font(.system(size: 17))
                .foregroundStyle(Palette.gold)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.primaryText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                if !suggestion.secondaryText.isEmpty {
                    Text(suggestion.secondaryText)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if resolvingPlaceID == suggestion.placeID {
                ProgressView()
                    .controlSize(.small)
                    .tint(Palette.gold)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .contentShape(.rect)
        .opacity(resolvingPlaceID == nil || resolvingPlaceID == suggestion.placeID ? 1 : 0.4)
    }

    // MARK: - Supporting cards

    private var currentLocationCard: some View {
        Button {
            useCurrentLocation()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "location.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Current location")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.primaryText)
                    Text(model.locationService.isDenied
                         ? "Location access is off in Settings"
                         : "Use where you are right now")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer(minLength: 0)
                if isLocating {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Palette.gold)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99))
        .disabled(isLocating)
        .panel()
    }

    private var hintCard: some View {
        messageCard(
            icon: "magnifyingglass",
            title: "Search for a place",
            message: "Start typing an address, business, or airport to see suggestions."
        )
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(Palette.gold)
            Text("Searching…")
                .font(.system(size: 15))
                .foregroundStyle(Palette.secondaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .panel()
    }

    private func messageCard(
        icon: String,
        title: String,
        message: String,
        retry: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.gold)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.primaryText)
            }
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let retry {
                Button("Try again", action: retry)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .panel()
    }

    private var attribution: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 11))
            Text("Powered by Google")
                .font(.system(size: 11))
        }
        .foregroundStyle(Palette.tertiaryText)
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    // MARK: - Behaviour

    /// Waits 300ms after typing stops before hitting the Places API.
    private func runDebouncedSearch() async {
        let text = trimmedQuery
        guard text.count >= 2 else {
            state = .idle
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        await runSearch(text)
    }

    private func runSearch(_ text: String) async {
        state = .loading
        do {
            let suggestions = try await PlacesService.autocomplete(
                query: text,
                bias: model.searchBias,
                sessionToken: sessionToken
            )
            guard !Task.isCancelled else { return }
            state = suggestions.isEmpty ? .empty : .results(suggestions)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(message(for: error))
        }
    }

    /// Resolves the tapped prediction to coordinates, then stores it in app state.
    private func select(_ suggestion: PlaceSuggestion) {
        guard resolvingPlaceID == nil else { return }
        resolvingPlaceID = suggestion.placeID

        Task {
            defer { resolvingPlaceID = nil }
            do {
                let place = try await PlacesService.details(
                    placeID: suggestion.placeID,
                    sessionToken: sessionToken
                )
                // A session ends with its details lookup.
                sessionToken = UUID().uuidString
                switch target {
                case .pickup: model.setPickup(place)
                case .destination: model.setDestination(place)
                }
                dismiss()
            } catch is CancellationError {
                return
            } catch {
                state = .failed(message(for: error))
            }
        }
    }

    private func useCurrentLocation() {
        guard !isLocating else { return }
        isLocating = true
        Task {
            let didResolve = await model.useCurrentLocationForPickup()
            isLocating = false
            if didResolve {
                dismiss()
            } else {
                state = .failed(
                    model.locationService.isDenied
                        ? "Location access is off. Turn it on in Settings, or search for your pickup instead."
                        : "Couldn't get your location. Search for your pickup instead."
                )
            }
        }
    }

    private func message(for error: Error) -> String {
        (error as? PlacesError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}

#Preview {
    PlaceSearchView(target: .destination)
        .environment(AppModel())
}
