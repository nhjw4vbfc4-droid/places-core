//
//  LocationProvider.swift
//  PlacesCore
//
//  Shared one-shot location source. Used to seed a "from here" origin, sort
//  pickers by proximity, and scan what's near you. Uses when-in-use
//  authorization (each app declares the usage string in its own Info.plist).
//
//  Moved verbatim from the Java Hunt app (its version was a superset of the
//  Jeeves one, adding `currentState`). Behavior is unchanged; only access
//  levels were widened to `public` so both apps can consume it across the
//  module boundary.
//

import Foundation
import CoreLocation
import Combine

public final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationProvider()

    private let manager = CLLocationManager()
    @Published public var location: CLLocation?
    /// The user's current state (e.g. "MA"), reverse-geocoded from `location`.
    /// Used to fill in a missing state on a typed address.
    @Published public var currentState: String?

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Ask for permission if needed and grab a fresh fix.
    public func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate
    // These are invoked by CoreLocation via the Objective-C runtime, so they do
    // not need to be `public` to be called.

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.location = loc }
        // Learn the user's state so a typed address missing one can assume it.
        Task {
            let placemarks = try? await CLGeocoder().reverseGeocodeLocation(loc)
            if let state = placemarks?.first?.administrativeArea {
                await MainActor.run { self.currentState = state }
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent — features that need a fix just stay quiet until one arrives.
    }
}
