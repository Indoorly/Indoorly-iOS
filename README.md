# IndoorSDK

Indoor store navigation for iOS: floor map, AR camera guidance, and multi-stop trips.

This package is **binary-only** (XCFramework). Engine source is not included.

| | |
| --- | --- |
| **Platform** | iOS 17+ (iPhone / iPad) |
| **Xcode** | 15+ |
| **Integration** | Swift Package Manager |
| **UI** | SwiftUI (`IndoorNavigationView`, `IndoorSurveyView`) |
| **Repository** | https://github.com/Indoorly/Indoorly-iOS |

---

## Table of contents

1. [Install](#1-install)
2. [Permissions (Info.plist)](#2-permissions-infoplist)
3. [Where to configure the SDK](#3-where-to-configure-the-sdk)
4. [Tokens](#4-tokens)
5. [Visitor app — end-to-end](#5-visitor-app--end-to-end)
6. [Presenting navigation](#6-presenting-navigation)
7. [Customization](#7-customization)
8. [Pin a venue & nearby radius](#8-pin-a-venue--nearby-radius)
9. [Callbacks](#9-callbacks)
10. [Custom screens with IndoorDirectory](#10-custom-screens-with-indoordirectory)
11. [Staff app — register / extend a store](#11-staff-app--register--extend-a-store)
12. [Device GPS & capabilities](#12-device-gps--capabilities)
13. [Advanced setup (without the facade)](#13-advanced-setup-without-the-facade)
14. [Telemetry](#14-telemetry)
15. [UIKit / AppDelegate apps](#15-uikit--appdelegate-apps)
16. [API reference (public surface)](#16-api-reference-public-surface)
17. [Common issues](#17-common-issues)
18. [Support](#18-support)

---

## 1. Install

### Xcode UI

1. **File → Add Package Dependencies…**
2. Paste: `https://github.com/Indoorly/Indoorly-iOS.git`
3. Choose a version (git tag, e.g. `1.0.1`)
4. Add the **IndoorSDK** product to your app target

### `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/Indoorly/Indoorly-iOS.git", from: "1.0.1"),
],
```

Then add `.product(name: "IndoorSDK", package: "Indoorly-iOS")` to your target.

> **Note:** Do not add this package to a target that already links a local IndoorSDK source package — SPM allows the product name only once.

---

## 2. Permissions (Info.plist)

Add these keys to your app target’s Info tab (or `Info.plist`):

| Key | Required when |
| --- | --- |
| `NSCameraUsageDescription` | Navigation with AR camera, or walking survey |
| `NSMotionUsageDescription` | Device heading while navigating |
| `NSLocationWhenInUseUsageDescription` | Filtering nearby stores with GPS (`IndoorLocation` / `venues(near:)`) |

Example strings:

```text
NSCameraUsageDescription = "Camera is used to guide you through the store."
NSMotionUsageDescription = "Motion is used to keep your heading on the map."
NSLocationWhenInUseUsageDescription = "Location is used to show nearby stores."
```

---

## 3. Where to configure the SDK

Call configuration **once at launch**, before any navigation or directory call.

| App style | Where to call `Indoorly.initialize` |
| --- | --- |
| SwiftUI `@main` | `App.init()` (recommended) |
| UIKit + `AppDelegate` | `application(_:didFinishLaunchingWithOptions:)` |
| UIKit + `SceneDelegate` only | First scene connect, **before** presenting Indoorly UI |
| Unit tests | `setUp` / test entry — use a test token if needed |

Also at launch (optional, still before UI):

- `Indoorly.appearance(...)`
- `Indoorly.venueID(...)`
- `Indoorly.enableAddMoreStores(...)`
- `Indoorly.telemetry(...)`

Do **not** call `initialize` again from every screen. Views only present `navigationView` / `surveyView` / `directory()`.

The production API URL is **baked into the SDK**. Host apps do not set it (optional `serviceURL:` exists only for local API debugging).

---

## 4. Tokens

Issued in the Indoorly admin panel (**Businesses → API Token**).

| Kind | Prefix | Use in host app |
| --- | --- | --- |
| API Token (visitors) | `pk_…` | Public / consumer apps |
| Admin Token | `sk_…` | Staff-only apps that register or extend stores |

```swift
// Visitor app
Indoorly.initialize(apiToken: "pk_…")
Indoorly.enableAddMoreStores(false)

// Staff app (register / extend a store by walking)
Indoorly.initialize(apiToken: "sk_…")
Indoorly.enableAddMoreStores(true)
```

Never ship an `sk_…` token inside a public App Store build.

---

## 5. Visitor app — end-to-end

### Step A — Configure at launch

```swift
import IndoorSDK
import SwiftUI

@main
struct MyApp: App {
    init() {
        Indoorly.initialize(apiToken: "pk_…")          // from admin panel
        Indoorly.enableAddMoreStores(false)
        Indoorly.telemetry(true)                       // optional; default is on
        Indoorly.appearance(
            IndoorAppearance(
                accentColor: Color(red: 0.0, green: 0.45, blue: 0.25),
                layout: .withHostBackButton            // room for your Back button
            )
        )
        // Optional: lock to one store
        // Indoorly.venueID("walmart-demo")
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
    }
}
```

### Step B — Own home screen, then open Indoorly

```swift
import IndoorSDK
import SwiftUI

struct HomeView: View {
    @State private var showNavigation = false
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("My Store App")
                .font(.largeTitle.bold())

            Button("Start indoor navigation") {
                showNavigation = true
            }
            .buttonStyle(.borderedProminent)

            if let loadError {
                Text(loadError).foregroundStyle(.red)
            }
        }
        .fullScreenCover(isPresented: $showNavigation) {
            NavigationHostView(isPresented: $showNavigation)
        }
    }
}
```

### Step C — Host wrapper with Back + SDK UI

`Indoorly.navigationView()` throws if the token was never set. Catch that when building the view, or use a small host wrapper:

```swift
import IndoorSDK
import SwiftUI

struct NavigationHostView: View {
    @Binding var isPresented: Bool
    /// Destination IDs from your backend / deep link / shopping list.
    var stops: [String] = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            navigationContent

            Button {
                isPresented = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.leading, 14)
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var navigationContent: some View {
        if let view = try? Indoorly.navigationView(stops: stops) {
            view
                .onArrival { place in
                    print("Arrived:", place.id, place.name, place.category)
                }
                .onVisitFinished { summary in
                    print(
                        "Done venue=\(summary.venueID)",
                        "stops=\(summary.visited.count)",
                        "meters=\(summary.walkedMeters)",
                        "seconds=\(summary.duration)"
                    )
                    isPresented = false
                }
        } else {
            ContentUnavailableView(
                "Indoorly not configured",
                systemImage: "exclamationmark.triangle",
                description: Text("Call Indoorly.initialize(apiToken:) at app launch.")
            )
        }
    }
}
```

Use `IndoorAppearance(layout: .withHostBackButton)` (or a custom `IndoorLayout` with `topLeadingReserved`) so SDK banners do not sit under your back control.

---

## 6. Presenting navigation

### Full-screen cover (typical)

```swift
.fullScreenCover(isPresented: $showNavigation) {
    NavigationHostView(isPresented: $showNavigation, stops: ["dairy", "bakery"])
}
```

### Push onto a `NavigationStack`

```swift
NavigationLink("Navigate") {
    NavigationHostView(isPresented: .constant(true), stops: [])
        .toolbar(.hidden, for: .navigationBar) // SDK draws its own chrome
}
```

Prefer **fullScreenCover** for AR navigation so system bars do not fight the camera UI.

### Pre-selected stops

```swift
// Empty list → visitor picks destinations inside the SDK
try Indoorly.navigationView(stops: [])

// Preload a multi-stop trip (place IDs from the panel / IndoorDirectory)
try Indoorly.navigationView(stops: ["dairy", "bakery", "pharmacy"])
```

Place IDs are the destination identifiers configured for that venue (not display names).

---

## 7. Customization

Call `Indoorly.appearance(...)` at launch (or before presenting navigation). Dynamic Type and light/dark mode follow the system.

### Brand colors & category icons — `IndoorAppearance`

```swift
let brand = IndoorAppearance(
    accentColor: Color(red: 0.0, green: 0.45, blue: 0.25),   // buttons, lists, chips
    arrivalColor: Color(red: 0.13, green: 0.75, blue: 0.38), // arrival / beacon
    trailColor: Color(red: 0.13, green: 0.75, blue: 0.38),   // walked trail on the map
    categoryIcons: [
        "dairy": "cup.and.saucer.fill",
        "pharmacy": "cross.case.fill",
        "bakery": "birthday.cake.fill",
    ],
    layout: .withHostBackButton   // or .standard / custom IndoorLayout
)

Indoorly.appearance(brand)
```

A place’s own icon (from the panel) wins over `categoryIcons`.

### Chrome layout — `IndoorLayout`

Controls banners, mini-map, and space for host chrome over the SDK.

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
| `topPadding` / `horizontalPadding` | Insets under the safe area |
| `chromeSpacing` | Gap between maneuver banner, tracking banner, controls |
| `showsManeuverBanner` | Turn / distance instruction |
| `showsTrackingBanner` | AR localization status |
| `showsMiniMap` | Mini-map while the camera is active |
| `miniMapSize` / paddings | Mini-map size and placement |

---

## 8. Pin a venue & nearby radius

```swift
// Show only this store (skip venue picker when the token has several venues)
Indoorly.venueID("walmart-demo")

// Clear pin → list all venues for the token
Indoorly.venueID(nil)

// Optional GPS preference used by host “nearby” flows (0 = no preference)
Indoorly.nearbyRadiusMeters(2_000)
```

---

## 9. Callbacks

```swift
try Indoorly.navigationView(stops: ["pharmacy"])
    .onArrival { place in
        // Called each time the visitor reaches a stop
        // place.id, place.name, place.category, place.x, place.y (floor-plan meters)
    }
    .onVisitFinished { summary in
        // Called when the visitor ends the visit
        // summary.venueID, summary.visited, summary.walkedMeters, summary.duration
    }
```

Wire analytics, receipts, or dismissal of your `fullScreenCover` inside these handlers.

---

## 10. Custom screens with `IndoorDirectory`

Use the directory when you build **your own** venue / destination UI and only open the SDK for walking.

```swift
import IndoorSDK
import CoreLocation
import SwiftUI

@MainActor
final class StoreBrowserModel: ObservableObject {
    @Published var venues: [IndoorVenueInfo] = []
    @Published var places: [IndoorPlaceInfo] = []
    @Published var errorMessage: String?

    func loadVenues() async {
        do {
            let directory = try Indoorly.directory()
            venues = try await directory.venues()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func loadNearby(coordinate: CLLocationCoordinate2D) async {
        do {
            let directory = try Indoorly.directory()
            venues = try await directory.venues(near: coordinate, radiusMeters: 2_000)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func loadPlaces(venueID: String) async {
        do {
            let directory = try Indoorly.directory()
            places = try await directory.places(venueID: venueID)
        } catch {
            errorMessage = String(describing: error)
        }
    }
}

struct StoreBrowserView: View {
    @StateObject private var model = StoreBrowserModel()
    @State private var showNavigation = false
    @State private var selectedStops: [String] = []

    var body: some View {
        List {
            ForEach(model.venues) { venue in
                Button(venue.name) {
                    Indoorly.venueID(venue.id)
                    showNavigation = true
                }
            }
        }
        .task { await model.loadVenues() }
        .fullScreenCover(isPresented: $showNavigation) {
            NavigationHostView(isPresented: $showNavigation, stops: selectedStops)
        }
    }
}
```

`IndoorPlaceInfo.x` / `.y` are **floor-plan meters**, not GPS.

### Admin-only directory writes

Requires an `sk_…` token:

```swift
let directory = try Indoorly.directory()

try await directory.addPlace(
    venueID: "walmart-demo",
    name: "Wine",
    category: "liquor"   // or pass x: / y: in floor-plan meters
)
try await directory.updatePlace(venueID: "walmart-demo", placeID: "dairy", name: "Dairy")
try await directory.removePlace(venueID: "walmart-demo", placeID: "dairy")
```

---

## 11. Staff app — register / extend a store

Staff builds must use `sk_…` and `enableAddMoreStores(true)`.

```swift
@main
struct StaffApp: App {
    init() {
        Indoorly.initialize(apiToken: "sk_…")
        Indoorly.enableAddMoreStores(true)
        Indoorly.appearance(IndoorAppearance(layout: .withHostBackButton))
    }

    var body: some Scene {
        WindowGroup {
            StaffHomeView()
        }
    }
}

struct StaffHomeView: View {
    @State private var showSurvey = false

    var body: some View {
        Button("Register store by walking") { showSurvey = true }
            .fullScreenCover(isPresented: $showSurvey) {
                SurveyHostView(isPresented: $showSurvey)
            }
    }
}

struct SurveyHostView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let survey = try? Indoorly.surveyView(venue: .new(name: "Downtown Store")) {
                survey
                    .onFinish { venue in
                        print("Saved", venue.id, venue.name)
                        isPresented = false
                    }
                    .onCancel {
                        isPresented = false
                    }
            } else {
                ContentUnavailableView(
                    "Survey unavailable",
                    systemImage: "lock",
                    description: Text("Needs sk_… token and enableAddMoreStores(true).")
                )
            }

            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
        }
    }
}
```

Venue modes:

```swift
// Create a new store (id derived from name when omitted)
.surveyView(venue: .new(name: "Downtown Store"))
.surveyView(venue: .new(name: "Downtown Store", id: "downtown-01"))

// Extend a store that was surveyed before (relocalize + add to world map)
.surveyView(venue: .existing(id: "downtown-01"))
```

---

## 12. Device GPS & capabilities

### GPS helper

```swift
import IndoorSDK
import CoreLocation

let location = IndoorLocation()
location.requestWhenInUse()
location.start()

// Observe:
// location.coordinate
// location.authorization   // .notDetermined / .denied / .authorizedWhenInUse / …
location.stop()
```

### Device capabilities

```swift
let caps = IndoorDeviceCapabilities.current
// caps.supportsWorldTracking
// caps.hasLiDAR
// caps.supportsSceneDepth
```

LiDAR does not unlock extra features in this version. Navigation uses a 2D floor graph plus `ARWorldMap` relocalization when the venue was surveyed with a world map.

On Simulator (or devices without world tracking), the **map preview** still works; the AR camera path will not.

---

## 13. Advanced setup (without the facade)

When you need per-screen configuration instead of the global `Indoorly` settings:

```swift
let config = IndoorConfiguration(
    serviceURL: Indoorly.productionServiceURL,
    clientToken: "pk_…",
    venueID: "walmart-demo",
    appearance: IndoorAppearance(layout: .withHostBackButton),
    hostOptions: IndoorHostOptions(allowsSurvey: false)
)

IndoorNavigationView(configuration: config, stops: ["pharmacy"])
    .onArrival { _ in }
    .onVisitFinished { _ in }
```

Survey without the facade:

```swift
let surveyConfig = IndoorSurveyConfiguration(
    serviceURL: Indoorly.productionServiceURL,
    adminToken: "sk_…",
    venue: .new(name: "Downtown Store"),
    appearance: .standard
)

IndoorSurveyView(configuration: surveyConfig)
    .onFinish { _ in }
    .onCancel { }
```

---

## 14. Telemetry

By default the SDK reports sessions, arrivals, and failures to Indoorly (analytics panel).

```swift
Indoorly.telemetry(false)   // opt out — call at launch with initialize
```

---

## 15. UIKit / AppDelegate apps

### Configure in `AppDelegate`

```swift
import UIKit
import IndoorSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Indoorly.initialize(apiToken: "pk_…")
        Indoorly.enableAddMoreStores(false)
        Indoorly.appearance(IndoorAppearance(layout: .withHostBackButton))
        return true
    }
}
```

### Present SwiftUI from UIKit

```swift
import SwiftUI
import IndoorSDK
import UIKit

final class HomeViewController: UIViewController {
    @IBAction func startNavigation() {
        guard let nav = try? Indoorly.navigationView(stops: []) else { return }
        let host = UIHostingController(
            rootView: nav
                .onArrival { place in print(place.name) }
                .onVisitFinished { _ in self.dismiss(animated: true) }
        )
        host.modalPresentationStyle = .fullScreen
        present(host, animated: true)
    }
}
```

---

## 16. API reference (public surface)

| API | Role |
| --- | --- |
| `Indoorly.initialize(apiToken:serviceURL:)` | Required once at launch |
| `Indoorly.appearance(_:)` | Brand colors, icons, layout |
| `Indoorly.venueID(_:)` | Pin or clear venue |
| `Indoorly.enableAddMoreStores(_:)` | Allow survey UI (needs `sk_…`) |
| `Indoorly.telemetry(_:)` | Opt in/out of usage events |
| `Indoorly.nearbyRadiusMeters(_:)` | GPS radius preference for host flows |
| `Indoorly.navigationView(stops:)` | Full navigation UI |
| `Indoorly.surveyView(venue:)` | Walking survey / register UI |
| `Indoorly.directory()` | Venues & places API for custom screens |
| `Indoorly.configuration(venueID:)` | Build `IndoorConfiguration` from facade |
| `IndoorNavigationView` | Navigation UI (advanced init) |
| `IndoorSurveyView` | Survey UI (advanced init) |
| `IndoorAppearance` / `IndoorLayout` | Visual customization |
| `IndoorPlaceInfo` / `IndoorVenueInfo` / `IndoorVisitSummary` | Models |
| `IndoorLocation` | When-in-use GPS helper |
| `IndoorDeviceCapabilities` | AR / LiDAR probes |
| `IndoorError` | `unauthorized`, `adminTokenRequired`, `unknownVenue`, … |

Readable state after configure: `Indoorly.isConfigured`, `apiToken`, `configuredVenueID`, `configuredAppearance`, `addMoreStoresEnabled`, etc.

---

## 17. Common issues

| Situation | Check |
| --- | --- |
| Xcode shows nothing after `Indoorly.` | Update package to **1.0.1+**, Clean Build Folder, rebuild |
| 401 / unauthorized | Empty token, rotated token, or `sk_` used by mistake in a visitor app |
| `Indoorly.navigationView` throws / nil | `initialize` was never called, or token string is empty |
| No venues | Business has no stores in the admin panel yet |
| Camera does not open | Simulator or device without `ARWorldTracking`; map preview still works |
| Register / survey UI missing | Needs `sk_…` **and** `enableAddMoreStores(true)` |
| Banners under your Back button | Use `IndoorLayout.withHostBackButton` or raise `topLeadingReserved` |
| SPM product conflict | Same target cannot link both local IndoorSDK source and this binary package |

---

## 18. Support

- **Tokens, venues, destinations, analytics:** your organization’s Indoorly admin panel  
- **Package versions:** git tags on this repository (SPM)  
- **Release assets:** [Releases](https://github.com/Indoorly/Indoorly-iOS/releases) (XCFramework zip only — no source)
