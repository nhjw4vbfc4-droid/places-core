// swift-tools-version: 5.9
import PackageDescription

// Shared foundation for Jeeves and Java Hunt. Holds the logic both apps would
// otherwise duplicate (location, geocoding, and — later — the route/coffee
// search engine). Each app consumes it as a normal SPM dependency; removing the
// dependency returns an app to fully standalone.
let package = Package(
    name: "PlacesCore",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v13), // host platform for `swift test` on CI
    ],
    products: [
        .library(name: "PlacesCore", targets: ["PlacesCore"]),
    ],
    targets: [
        .target(name: "PlacesCore"),
        .testTarget(name: "PlacesCoreTests", dependencies: ["PlacesCore"]),
    ]
)
