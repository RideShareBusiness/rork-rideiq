//
//  RideRoute.swift
//  RideSelect
//

import Foundation

/// A resolved geographic point for a pickup or destination.
nonisolated struct PlaceCoordinate: Hashable, Codable, Sendable {
    let latitude: Double
    let longitude: Double

    /// Great-circle distance to another coordinate, in miles.
    func distance(to other: PlaceCoordinate) -> Double {
        let earthRadiusMiles = 3958.8
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let deltaLat = (other.latitude - latitude) * .pi / 180
        let deltaLon = (other.longitude - longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMiles * c
    }
}

/// A pickup or destination, normally resolved from Google Places.
nonisolated struct Place: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let detail: String
    /// Rough miles from downtown, used only when real coordinates are unavailable.
    let distanceHint: Double
    let isAirport: Bool
    /// Google place identifier, when this place came from Places autocomplete.
    let placeID: String?
    let latitude: Double?
    let longitude: Double?

    init(
        id: UUID = UUID(),
        name: String,
        detail: String,
        distanceHint: Double,
        isAirport: Bool = false,
        placeID: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.distanceHint = distanceHint
        self.isAirport = isAirport
        self.placeID = placeID
        self.latitude = latitude
        self.longitude = longitude
    }

    /// The resolved lat/lng, when this place has been geocoded.
    var coordinate: PlaceCoordinate? {
        guard let latitude, let longitude else { return nil }
        return PlaceCoordinate(latitude: latitude, longitude: longitude)
    }

    var isResolved: Bool { coordinate != nil }

    /// Placeholder pickup shown before the device location resolves.
    static let currentLocation = Place(
        name: "Current Location",
        detail: "Using your device location",
        distanceHint: 0
    )

    /// Placeholder destination before the rider has chosen one.
    static let unset = Place(name: "Where to?", detail: "", distanceHint: 4.2)

    /// Stable pseudo-distance used only if a place never resolved to coordinates.
    static func fallbackDistanceHint(for text: String) -> Double {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in Array(text.lowercased().utf8) {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01B3
        }
        return 2.5 + Double(hash % 90) / 10.0
    }
}

/// The pickup → destination pair currently being compared.
nonisolated struct RideRoute: Hashable, Codable {
    var pickup: Place
    var destination: Place

    var isAirportTrip: Bool { pickup.isAirport || destination.isAirport }

    /// Road-distance estimate in miles derived from the resolved coordinates.
    /// Straight-line distance is padded to approximate real street routing.
    var distanceMiles: Double? {
        guard let start = pickup.coordinate, let end = destination.coordinate else { return nil }
        return max(0.6, start.distance(to: end) * 1.25)
    }
}
