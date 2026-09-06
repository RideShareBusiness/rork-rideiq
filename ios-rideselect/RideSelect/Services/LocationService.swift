//
//  LocationService.swift
//  RideSelect
//

import CoreLocation
import Foundation

/// Wraps CoreLocation so the pickup field can default to where the rider is.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    /// Why a location lookup could not produce a coordinate.
    nonisolated enum Failure: Error {
        case denied
        case unavailable
    }

    private(set) var isResolving: Bool = false
    private(set) var isDenied: Bool = false
    private(set) var lastCoordinate: PlaceCoordinate?

    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<PlaceCoordinate, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Resolves the device location into a `Place` suitable for the pickup field.
    /// Returns `nil` when permission is denied or no fix is available.
    func resolveCurrentPlace() async -> Place? {
        guard !isResolving else { return nil }
        isResolving = true
        defer { isResolving = false }

        do {
            let coordinate = try await requestCoordinate()
            lastCoordinate = coordinate
            isDenied = false
            let described = await ReverseGeocoder.describe(coordinate)
            return Place(
                name: described?.name ?? "Current Location",
                detail: described?.detail ?? "Your current location",
                distanceHint: 0,
                isAirport: described?.name.localizedCaseInsensitiveContains("airport") ?? false,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch Failure.denied {
            isDenied = true
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Permission + fix

    private func requestCoordinate() async throws -> PlaceCoordinate {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw Failure.denied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
            startWatchdog()
        }
    }

    /// Some devices and simulators never deliver a fix; don't hang the UI forever.
    private func startWatchdog() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, let continuation = self.locationContinuation else { return }
            self.locationContinuation = nil
            continuation.resume(throwing: Failure.unavailable)
        }
    }

    private func finishAuthorization(_ status: CLAuthorizationStatus) {
        guard status != .notDetermined, let continuation = authorizationContinuation else { return }
        authorizationContinuation = nil
        continuation.resume(returning: status)
    }

    private func finishLocation(with result: Result<PlaceCoordinate, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.finishAuthorization(status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = PlaceCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        Task { @MainActor [weak self] in
            self?.finishLocation(with: .success(coordinate))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let isDenied = (error as? CLError)?.code == .denied
        Task { @MainActor [weak self] in
            self?.finishLocation(with: .failure(isDenied ? Failure.denied : Failure.unavailable))
        }
    }
}

/// Turns a coordinate into a short, human-readable label for the pickup row.
private nonisolated enum ReverseGeocoder {
    struct Description {
        let name: String
        let detail: String
    }

    static func describe(_ coordinate: PlaceCoordinate) async -> Description? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return nil
        }

        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        let area = [placemark.subLocality, placemark.locality]
            .compactMap { $0 }
            .joined(separator: ", ")

        let name = street.isEmpty ? (placemark.name ?? placemark.locality ?? "Current Location") : street
        let detail = area.isEmpty ? "Your current location" : area
        return Description(name: name, detail: detail)
    }
}
