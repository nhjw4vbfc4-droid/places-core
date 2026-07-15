// swift-tools-version: 5.9
import PackageDescription

// Shared foundation for Jeeves and Java Hunt. Holds the logic both apps would
// otherwise duplicate (location, geocoding, and — later — the route/coffee
// search engine). Each app consumes it as a normal SPM dependency; removing the
// dependency returns an app to fully standalone.
//
// Platforms are iOS + Mac Catalyst only — the two targets the apps actually
// ship. (Native macOS is intentionally excluded: some CoreLocation API used
// here is unavailable there, and neither app runs on native macOS.)
let package = Package(
    name: "PlacesCore",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
    ],
    products: [
        .library(name: "PlacesCore", targets: ["PlacesCore"]),
    ],
    targets: [
        .target(name: "PlacesCore"),
        .testTarget(name: "PlacesCoreTests", dependencies: ["PlacesCore"]),
    ]
)
