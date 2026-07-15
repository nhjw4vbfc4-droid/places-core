# PlacesCore

Shared Swift package for **Jeeves** and **Java Hunt** (repo currently named `Private` — safe to rename to `places-core`).

Holds the logic both apps would otherwise duplicate — location, geocoding, and
(as it grows) the route/coffee search engine — so a fix in one place reaches
both apps instead of drifting between two copies.

## Consuming it

Each app adds this repository as a Swift Package dependency and `import PlacesCore`.
Removing the dependency returns an app to fully standalone — nothing here is
load-bearing for an app that stops using it.

## Contents

| Component | Status |
|-----------|--------|
| `LocationProvider` | One-shot Core Location source (+ current-state reverse geocode) |

More to come, one verified extraction at a time.
