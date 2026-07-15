import XCTest
import CoreLocation
@testable import PlacesCore

final class LocationProviderTests: XCTestCase {
    /// The shared instance is reachable and starts empty. This mainly proves the
    /// module compiles, links, and exposes its public surface across the module
    /// boundary — the real value LocationProvider adds (a live GPS fix) can't be
    /// exercised on a headless CI runner.
    @MainActor
    func testSharedStartsEmpty() {
        let provider = LocationProvider.shared
        XCTAssertNil(provider.location)
        XCTAssertNil(provider.currentState)
    }
}
