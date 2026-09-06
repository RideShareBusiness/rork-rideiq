//
//  RideProvider.swift
//  RideSelect
//

import Foundation

/// The three premium ride options RideSelect compares. Economy tiers are intentionally excluded.
nonisolated enum RideProvider: String, CaseIterable, Codable, Identifiable, Hashable {
    case waymo
    case uberBlack
    case lyftBlack

    var id: String { rawValue }

    /// Full label used in headers and buttons, e.g. "Uber Black".
    var displayName: String {
        switch self {
        case .waymo: "Waymo"
        case .uberBlack: "Uber Black"
        case .lyftBlack: "Lyft Black"
        }
    }

    /// Brand only, used by the compact provider mark.
    var brandName: String {
        switch self {
        case .waymo: "Waymo"
        case .uberBlack: "Uber"
        case .lyftBlack: "Lyft"
        }
    }

    var rideType: String {
        switch self {
        case .waymo: "Autonomous"
        case .uberBlack: "Black car"
        case .lyftBlack: "Black car"
        }
    }

    var isAutonomous: Bool { self == .waymo }

    /// True for the human-driven premium black car tiers.
    var isBlackCar: Bool { self != .waymo }
}
