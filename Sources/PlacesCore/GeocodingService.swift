//
//  GeocodingService.swift
//  PlacesCore
//
//  Apple's CLGeocoder rate-limits aggressively and cancels overlapping
//  requests on the same instance. This actor funnels every geocode through one
//  serialized, cached, retrying path so requests don't stampede and repeated
//  addresses only resolve once.
//
//  Moved from the apps (Java Hunt's version, a superset of the Jeeves one — it
//  adds the "assume the user's state when an address names none" helper).
//  Behavior is unchanged; access was widened to public, and the thrown error is
//  the package's own GeocodingError instead of each app's RouteSearchError.
//

import Foundation
import CoreLocation

/// Thrown when an address can't be geocoded.
public enum GeocodingError: LocalizedError {
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .failed(let address): return "Couldn't find location: \(address)"
        }
    }
}

public actor GeocodingService {
    public static let shared = GeocodingService()

    private var cache: [String: CLLocationCoordinate2D] = [:]
    private var tail: Task<Void, Never>?

    public func coordinate(for address: String) async throws -> CLLocationCoordinate2D {
        let key = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { throw GeocodingError.failed(address) }
        if let cached = cache[key] { return cached }

        // Chain after the previous request so only one runs at a time.
        let previous = tail
        let work = Task { () throws -> CLLocationCoordinate2D in
            _ = await previous?.value
            return try await Self.geocode(address)
        }
        tail = Task { _ = try? await work.value }

        let coord = try await work.value
        cache[key] = coord
        return coord
    }

    /// Like `coordinate(for:)`, but when the address names no US state and we
    /// know the user's state, try "<address>, <state>" first. That only resolves
    /// if the state actually has a place by that name; otherwise we fall back to
    /// the address exactly as typed.
    public func coordinate(for address: String, assumingStateIfMissing state: String?) async throws -> CLLocationCoordinate2D {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if let state, !state.isEmpty, !trimmed.isEmpty, !Self.mentionsState(trimmed) {
            if let coord = try? await coordinate(for: "\(trimmed), \(state)") {
                return coord
            }
        }
        return try await coordinate(for: address)
    }

    /// US state postal codes + names — to tell whether an address already names a state.
    private static let stateCodes: Set<String> = [
        "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
        "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
        "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
        "VA","WA","WV","WI","WY","DC"
    ]
    private static let stateNames: Set<String> = [
        "alabama","alaska","arizona","arkansas","california","colorado","connecticut",
        "delaware","florida","georgia","hawaii","idaho","illinois","indiana","iowa",
        "kansas","kentucky","louisiana","maine","maryland","massachusetts","michigan",
        "minnesota","mississippi","missouri","montana","nebraska","nevada",
        "new hampshire","new jersey","new mexico","new york","north carolina",
        "north dakota","ohio","oklahoma","oregon","pennsylvania","rhode island",
        "south carolina","south dakota","tennessee","texas","utah","vermont",
        "virginia","washington","west virginia","wisconsin","wyoming",
        "district of columbia"
    ]

    /// True when a comma-separated component is a state name, or a token like
    /// "MA" / "MA 02062" carries a state postal code.
    static func mentionsState(_ address: String) -> Bool {
        for part in address.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if stateNames.contains(part.lowercased()) { return true }
            for tok in part.split(separator: " ").map(String.init) {
                if stateCodes.contains(tok.uppercased()) { return true }
            }
        }
        return false
    }

    private static func geocode(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        for attempt in 0..<3 {
            do {
                let placemarks = try await geocoder.geocodeAddressString(address)
                if let coord = placemarks.first?.location?.coordinate {
                    // Small spacing keeps us under Apple's geocoder rate limit.
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    return coord
                }
                throw GeocodingError.failed(address)
            } catch {
                // Retry the transient throttle/network errors; give up on the rest.
                if let cl = error as? CLError,
                   cl.code == .geocodeFoundNoResult || cl.code == .network,
                   attempt < 2 {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    continue
                }
                throw GeocodingError.failed(address)
            }
        }
        throw GeocodingError.failed(address)
    }
}
