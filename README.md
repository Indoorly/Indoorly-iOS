# IndoorSDK

Indoor store navigation: floor map, AR camera guidance, and multi-stop trips.  
This package is **binary-only** (XCFramework). Engine source is not included.

**Requirements:** iOS 17+, Xcode 15+, Swift Package Manager.

---

## Install (SPM)

1. Xcode → **File → Add Package Dependencies…**
2. Paste this repository URL.
3. Pick a version (tag) and add the **IndoorSDK** product to your target.

```swift
dependencies: [
    .package(url: "https://github.com/Indoorly/Indoorly-iOS.git", from: "1.0.0"),
]
```

### App Info.plist

| Key | When |
| --- | --- |
| `NSCameraUsageDescription` | Navigation / walking survey with camera |
| `NSMotionUsageDescription` | Device heading |
| `NSLocationWhenInUseUsageDescription` | Only if you filter nearby stores (GPS) |

---

## Quick start

Tokens are issued in the Indoorly admin panel (**Businesses** → API Token `pk_…` for visitors).

```swift
import IndoorSDK
import SwiftUI

@main
struct MyApp: App {
    init() {
        Indoorly.initialize(apiToken: "pk_…")
        Indoorly.enableAddMoreStores(false)   // visitor apps: always false
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                // Your screen that presents Indoorly.navigationView()
                ContentView()
            }
        }
    }
}
```

```swift
// Present full-screen navigation
try Indoorly.navigationView(stops: [])   // or destination IDs: ["dairy", "bakery"]
    .onArrival { place in /* IndoorPlaceInfo */ }
    .onVisitFinished { summary in /* duration, meters, visited */ }
```

The production API URL is **baked into the SDK**. Do not configure it in the host app.

---

## Tokens

| Kind | Prefix | Use |
| --- | --- | --- |
| API Token (visitors) | `pk_…` | `Indoorly.initialize` in the public app |
| Admin Token | `sk_…` | Staff-only apps + `enableAddMoreStores(true)` |

```swift
// Visitor app
Indoorly.initialize(apiToken: "pk_…")
Indoorly.enableAddMoreStores(false)

// Staff app (register / extend a store by walking)
Indoorly.initialize(apiToken: "sk_…")
Indoorly.enableAddMoreStores(true)
try Indoorly.surveyView(venue: .new(name: "Downtown Store"))
    .onFinish { venue in }
    .onCancel { }
```

---

## Customization

### Colors and icons — `IndoorAppearance`

```swift
var brand = IndoorAppearance(
    accentColor: Color(red: 0.0, green: 0.45, blue: 0.25),   // buttons, list, chips
    arrivalColor: Color(red: 0.13, green: 0.75, blue: 0.38), // arrival / beacon
    trailColor: Color(red: 0.13, green: 0.75, blue: 0.38),   // walked trail
    categoryIcons: [
        "dairy": "cup.and.saucer.fill",
        "pharmacy": "cross.case.fill",
    ],
    layout: .withHostBackButton   // or .standard / custom IndoorLayout
)

Indoorly.appearance(brand)
```

Dynamic Type and light/dark mode follow the system.

### Chrome layout — `IndoorLayout`

Controls banners, mini-map, and space for your host “Back” button over the SDK.

```swift
let layout = IndoorLayout(
    topLeadingReserved: 56,   // room for host back button
    topPadding: 6,
    horizontalPadding: 14,
    chromeSpacing: 10,
    showsManeuverBanner: true,
    showsTrackingBanner: true,
    showsMiniMap: true,
    miniMapSize: 128,
    miniMapLeadingPadding: 16,
    miniMapBottomPadding: 16
)

Indoorly.appearance(IndoorAppearance(layout: layout))

// Shortcut when you only need space for a circular back control:
Indoorly.appearance(IndoorAppearance(layout: .withHostBackButton))
```

| Property | Effect |
| --- | --- |
| `topLeadingReserved` | Keeps banners clear of top-leading host chrome |
| `showsManeuverBanner` | Turn / distance instruction |
| `showsTrackingBanner` | AR localization status |
| `showsMiniMap` | Mini-map while the camera is active |

### Pin one venue

```swift
Indoorly.venueID("walmart-demo")   // nil = list all venues for the token
```

### Usage telemetry

By default the SDK reports sessions, arrivals, and failures to Indoorly (analytics panel).

```swift
Indoorly.telemetry(false)   // opt out
```

---

## Custom screens — `IndoorDirectory`

If you do not want the full navigation UI and only need venues/destinations:

```swift
let directory = try Indoorly.directory()

let venues = try await directory.venues()
let nearby = try await directory.venues(near: coordinate, radiusMeters: 2_000)
let places = try await directory.places(venueID: "walmart-demo")

// Admin Token only:
try await directory.addPlace(venueID: "walmart-demo", name: "Wine", category: "liquor")
try await directory.updatePlace(venueID: "walmart-demo", placeID: "dairy", name: "Dairy")
try await directory.removePlace(venueID: "walmart-demo", placeID: "dairy")
```

`IndoorPlaceInfo.x` / `.y` are **floor-plan meters** (not GPS).

### Device GPS

```swift
let location = IndoorLocation()
location.requestWhenInUse()
location.start()
// location.coordinate / authorization
```

### Device capabilities

```swift
let caps = IndoorDeviceCapabilities.current
// caps.supportsWorldTracking, caps.hasLiDAR, caps.supportsSceneDepth
```

LiDAR does not enable extra features in this version; navigation uses a 2D graph + ARWorldMap.

---

## Advanced setup (without the facade)

```swift
let config = IndoorConfiguration(
    serviceURL: Indoorly.productionServiceURL,
    clientToken: "pk_…",
    venueID: "walmart-demo",
    appearance: .standard,
    hostOptions: IndoorHostOptions(allowsSurvey: false)
)
IndoorNavigationView(configuration: config, stops: ["pharmacy"])
```

---

## Callbacks

```swift
try Indoorly.navigationView()
    .onArrival { place in
        // place.id, place.name, place.category
    }
    .onVisitFinished { summary in
        // summary.visited, summary.walkedMeters, summary.duration
    }
```

---

## Common issues

| Situation | Check |
| --- | --- |
| 401 / unauthorized | Empty token, rotated token, or `sk_` used by mistake in a visitor app |
| No venues | Business has no stores in the panel yet |
| Camera does not open | Simulator or device without ARWorldTracking; map preview still works |
| Register UI missing | Needs `sk_…` + `enableAddMoreStores(true)` |

---

## Support

Tokens, venues, and analytics: your organization’s Indoorly admin panel.  
Package version: git tags on this repository (SPM).
