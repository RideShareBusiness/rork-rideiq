//
//  AppModel.swift
//  RideSelect
//

import Foundation
import SwiftUI

/// Where the app currently is: the clean home screen, or the compare shell.
enum AppPhase: Equatable {
    case home
    case comparing
}

/// Single source of truth for the prototype: route, quotes, preferences, and trips.
@Observable
final class AppModel {
    private enum StorageKey {
        static let preferences = "rideselect.preferences"
        static let trips = "rideselect.trips"
    }

    private(set) var phase: AppPhase = .home

    var route = RideRoute(pickup: .currentLocation, destination: .unset)
    var hasChosenDestination: Bool = false

    /// Device location, used to default the pickup and to bias autocomplete.
    let locationService = LocationService()

    /// True once the rider has overridden pickup with their own search result.
    private(set) var hasCustomPickup: Bool = false

    private(set) var quotes: [RideQuote] = []
    private(set) var isSearching: Bool = false
    private(set) var lastUpdated: Date = .now
    private var quoteVariation: Int = 0

    var preferences: RidePreferences = .default {
        didSet {
            guard preferences != oldValue else { return }
            persistPreferences()
        }
    }

    private(set) var trips: [Trip] = []

    /// Quote pending confirmation in the booking sheet.
    var bookingCandidate: RideQuote?

    init() {
        loadPreferences()
        loadTrips()
    }

    // MARK: - Derived state

    /// Quotes ranked and badged for the current preferences.
    var rankedQuotes: [RankedQuote] {
        RecommendationEngine.rank(
            quotes: quotes,
            preferences: preferences,
            isAirportTrip: route.isAirportTrip
        )
    }

    var recommended: RankedQuote? {
        rankedQuotes.first { $0.isBestOverall }
    }

    var canCompare: Bool { hasChosenDestination }

    /// What the pickup row should read while location resolves.
    var pickupTitle: String {
        if hasCustomPickup || route.pickup.isResolved { return route.pickup.name }
        if locationService.isResolving { return "Locating…" }
        if locationService.isDenied { return "Set pickup location" }
        return route.pickup.name
    }

    var isPickupResolving: Bool { !hasCustomPickup && locationService.isResolving }

    /// Coordinate used to bias autocomplete toward the rider.
    var searchBias: PlaceCoordinate? {
        route.pickup.coordinate ?? locationService.lastCoordinate
    }

    // MARK: - Location

    /// Fills the pickup field from the device location on first launch of the home screen.
    func bootstrapPickup() async {
        guard !hasCustomPickup, !route.pickup.isResolved else { return }
        guard let place = await locationService.resolveCurrentPlace() else { return }
        guard !hasCustomPickup else { return }
        route.pickup = place
        if phase == .comparing { refreshQuotes() }
    }

    /// Explicitly re-resolves the device location for pickup. Returns false if unavailable.
    @discardableResult
    func useCurrentLocationForPickup() async -> Bool {
        guard let place = await locationService.resolveCurrentPlace() else { return false }
        hasCustomPickup = false
        route.pickup = place
        if phase == .comparing { refreshQuotes() }
        return true
    }

    // MARK: - Flow

    /// Runs a short mock search, then shows the compare shell.
    func compareRides() async {
        guard canCompare else { return }
        isSearching = true
        phase = .comparing
        quoteVariation = 0
        try? await Task.sleep(for: .milliseconds(1250))
        refreshQuotes()
        isSearching = false
    }

    /// Re-quotes with a nudged seed, as if prices had just moved.
    func refreshQuotes(nudge: Bool = false) {
        if nudge { quoteVariation += 1 }
        quotes = RideQuoteService.quotes(for: route, at: .now, variation: quoteVariation)
        lastUpdated = .now
    }

    func returnHome() {
        phase = .home
    }

    func setDestination(_ place: Place) {
        route.destination = place
        hasChosenDestination = true
        if phase == .comparing {
            refreshQuotes()
        }
    }

    func setPickup(_ place: Place) {
        route.pickup = place
        hasCustomPickup = true
        if phase == .comparing {
            refreshQuotes()
        }
    }

    // MARK: - Booking

    func startBooking(for quote: RideQuote) {
        bookingCandidate = quote
    }

    /// Confirms the handoff: logs the trip and dismisses the sheet.
    func confirmBooking() {
        guard let quote = bookingCandidate else { return }
        let rival = quotes.filter { $0.id != quote.id }.max { $0.price < $1.price }
        var savedNote: String?
        if let rival, rival.price > quote.price {
            let saved = Int((rival.price - quote.price).rounded())
            savedNote = "Saved $\(saved) vs \(rival.provider.displayName)"
        }

        let trip = Trip(
            provider: quote.provider,
            pickupName: route.pickup.name,
            destinationName: route.destination.name,
            price: quote.price,
            pickupMinutes: quote.pickupMinutes,
            tripMinutes: quote.tripMinutes,
            savedVersus: savedNote
        )
        trips.insert(trip, at: 0)
        persistTrips()
        bookingCandidate = nil
    }

    func cancelBooking() {
        bookingCandidate = nil
    }

    func deleteTrips(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        persistTrips()
    }

    // MARK: - Persistence

    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.preferences),
              let decoded = try? JSONDecoder().decode(RidePreferences.self, from: data) else {
            return
        }
        preferences = decoded
    }

    private func persistPreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.preferences)
    }

    private func loadTrips() {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.trips),
              let decoded = try? JSONDecoder().decode([Trip].self, from: data) else {
            return
        }
        trips = decoded
    }

    private func persistTrips() {
        guard let data = try? JSONEncoder().encode(trips) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.trips)
    }
}
