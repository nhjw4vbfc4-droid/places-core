# PlacesCore (places-core) — project notes for Claude

**PlacesCore** is a shared **Swift package**, not an app. It holds the location /
geocoding (and, as it grows, route/search) logic that **Jeeves** and **Java Hunt**
would otherwise duplicate, so a fix reaches both apps instead of drifting between two
copies. It is the **Shared** drawer item — and it deliberately spans drawers: Jeeves
is Work, JavaHunt is Play, but the shared code serves both.

## Stack
- **SPM package** (`Package.swift`, swift-tools-version 5.9), library product
  **`PlacesCore`**. Source in `Sources/PlacesCore/`, tests in `Tests/`.
- Platforms: **iOS 17 + Mac Catalyst 17 only.** Native macOS is intentionally
  excluded (some CoreLocation API used here is unavailable there, and neither
  consuming app runs on native macOS).
- Depends only on `Foundation`, `CoreLocation`, `Combine` — no third-party deps.

## Public API (current)
- **`LocationProvider`** — one-shot Core Location source (+ current-state reverse
  geocode).
- **`GeocodingService`** (actor) + **`GeocodingError`** — forward/reverse geocoding.
  (JavaHunt's old `GeocodingService.swift` was removed when this became the shared home.)

Grows "one verified extraction at a time" — keep the public surface small and stable.

## Consumers
- **Jeeves** (`com.tbedard.FieldTravelAssistant`) and **Java Hunt**
  (`com.tbedard.JavaHunt`) each add this repo as an SPM dependency and `import PlacesCore`.
- Nothing here is load-bearing: removing the dependency returns an app to fully
  standalone.

## GitHub
- **Public**: `github.com/nhjw4vbfc4-droid/places-core`.

## Gotchas
- **Changing the public API affects BOTH Jeeves and Java Hunt** — coordinate a change
  across both consumers; a break here breaks two apps.
- **iOS + Mac Catalyst only** — do not add native-macOS-only assumptions; NetWatch (a
  macOS app) does not and can not consume this.
- **Public repo** — keep API keys/secrets out; those belong in each app's Keychain.
- It's a library — it doesn't ship or have a bundle id / App Store record of its own.
- README has a stale line ("repo currently named `Private`") — the repo is now
  `places-core`.
