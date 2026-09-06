//
//  PlacesService.swift
//  RideSelect
//

import Foundation

/// A single prediction returned by Places Autocomplete (New).
nonisolated struct PlaceSuggestion: Identifiable, Hashable, Sendable {
    let placeID: String
    /// Short name, e.g. "Ferry Building".
    let primaryText: String
    /// Supporting address line, e.g. "1 Ferry Building, San Francisco, CA".
    let secondaryText: String
    let isAirport: Bool

    var id: String { placeID }
}

/// User-presentable failures from place lookup.
nonisolated enum PlacesError: LocalizedError, Sendable {
    case missingAPIKey
    case offline
    case rejected(String)
    case unavailable

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Place search isn't configured yet."
        case .offline:
            "You appear to be offline."
        case .rejected(let message):
            message
        case .unavailable:
            "Place search is unavailable right now."
        }
    }
}

/// Google Places API (New): Autocomplete predictions and Place Details lookups.
nonisolated enum PlacesService {
    private static let baseURL = "https://places.googleapis.com/v1"
    private static let detailsFieldMask = "id,displayName,formattedAddress,shortFormattedAddress,location,types"

    private static var apiKey: String {
        Config.allValues["EXPO_PUBLIC_GOOGLE_PLACES_API_KEY"] ?? ""
    }

    static var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Autocomplete

    /// Predictions for what the rider has typed so far.
    /// - Parameters:
    ///   - bias: optional coordinate used to prefer nearby results.
    ///   - sessionToken: groups keystrokes with the eventual details lookup for billing.
    static func autocomplete(
        query: String,
        bias: PlaceCoordinate?,
        sessionToken: String
    ) async throws -> [PlaceSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard isConfigured else { throw PlacesError.missingAPIKey }
        guard let url = URL(string: "\(baseURL)/places:autocomplete") else {
            throw PlacesError.unavailable
        }

        let body = AutocompleteRequest(
            input: trimmed,
            sessionToken: sessionToken,
            languageCode: Locale.current.language.languageCode?.identifier ?? "en",
            locationBias: bias.map(AutocompleteRequest.LocationBias.init(around:))
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        applyAuthHeaders(to: &request)

        let data = try await send(request)
        guard let decoded = try? JSONDecoder().decode(AutocompleteResponse.self, from: data) else {
            throw PlacesError.unavailable
        }

        return (decoded.suggestions ?? []).compactMap { suggestion in
            guard let prediction = suggestion.placePrediction else { return nil }
            let primary = prediction.structuredFormat?.mainText?.text
                ?? prediction.text?.text
                ?? ""
            guard !primary.isEmpty else { return nil }
            return PlaceSuggestion(
                placeID: prediction.placeId,
                primaryText: primary,
                secondaryText: prediction.structuredFormat?.secondaryText?.text ?? "",
                isAirport: (prediction.types ?? []).contains("airport")
            )
        }
    }

    // MARK: - Details

    /// Resolves a prediction into a full place with latitude/longitude.
    static func details(placeID: String, sessionToken: String) async throws -> Place {
        guard isConfigured else { throw PlacesError.missingAPIKey }
        let escapedID = placeID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? placeID
        guard var components = URLComponents(string: "\(baseURL)/places/\(escapedID)") else {
            throw PlacesError.unavailable
        }
        components.queryItems = [URLQueryItem(name: "sessionToken", value: sessionToken)]
        guard let url = components.url else { throw PlacesError.unavailable }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(detailsFieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        applyAuthHeaders(to: &request)

        let data = try await send(request)
        guard let decoded = try? JSONDecoder().decode(PlaceDetailsResponse.self, from: data),
              let location = decoded.location else {
            throw PlacesError.unavailable
        }

        let name = decoded.displayName?.text
            ?? decoded.shortFormattedAddress
            ?? decoded.formattedAddress
            ?? "Selected place"
        let detail = decoded.formattedAddress ?? decoded.shortFormattedAddress ?? ""
        let types = decoded.types ?? []

        return Place(
            name: name,
            detail: detail,
            distanceHint: Place.fallbackDistanceHint(for: detail.isEmpty ? name : detail),
            isAirport: types.contains("airport") || name.localizedCaseInsensitiveContains("airport"),
            placeID: decoded.id ?? placeID,
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    // MARK: - Transport

    private static func applyAuthHeaders(to request: inout URLRequest) {
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // Lets the key be locked to this app in the Google Cloud console.
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
    }

    private static func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .cancelled:
                throw CancellationError()
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .dataNotAllowed:
                throw PlacesError.offline
            default:
                throw PlacesError.unavailable
            }
        }

        guard let http = response as? HTTPURLResponse else { throw PlacesError.unavailable }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(GoogleErrorResponse.self, from: data))?.error?.message
            throw PlacesError.rejected(friendlyMessage(status: http.statusCode, apiMessage: message))
        }
        return data
    }

    private static func friendlyMessage(status: Int, apiMessage: String?) -> String {
        switch status {
        case 400: "That search couldn't be processed."
        case 401, 403: "Place search was rejected — check the Google API key and its restrictions."
        case 429: "Too many searches right now. Try again in a moment."
        default: apiMessage ?? "Place search failed (\(status))."
        }
    }
}

// MARK: - Wire formats

private nonisolated struct AutocompleteRequest: Encodable {
    let input: String
    let sessionToken: String
    let languageCode: String
    let locationBias: LocationBias?

    struct LocationBias: Encodable {
        let circle: Circle

        init(around coordinate: PlaceCoordinate) {
            circle = Circle(
                center: Circle.Center(latitude: coordinate.latitude, longitude: coordinate.longitude),
                radius: 50_000
            )
        }

        struct Circle: Encodable {
            let center: Center
            let radius: Double

            struct Center: Encodable {
                let latitude: Double
                let longitude: Double
            }
        }
    }
}

private nonisolated struct AutocompleteResponse: Decodable {
    let suggestions: [Suggestion]?

    struct Suggestion: Decodable {
        let placePrediction: PlacePrediction?
    }

    struct PlacePrediction: Decodable {
        let placeId: String
        let text: FormattableText?
        let structuredFormat: StructuredFormat?
        let types: [String]?
    }

    struct StructuredFormat: Decodable {
        let mainText: FormattableText?
        let secondaryText: FormattableText?
    }

    struct FormattableText: Decodable {
        let text: String
    }
}

private nonisolated struct PlaceDetailsResponse: Decodable {
    let id: String?
    let displayName: DisplayName?
    let formattedAddress: String?
    let shortFormattedAddress: String?
    let location: LatLng?
    let types: [String]?

    struct DisplayName: Decodable {
        let text: String
    }

    struct LatLng: Decodable {
        let latitude: Double
        let longitude: Double
    }
}

private nonisolated struct GoogleErrorResponse: Decodable {
    let error: ErrorBody?

    struct ErrorBody: Decodable {
        let code: Int?
        let message: String?
        let status: String?
    }
}
