# IndoorSDK

Navegación indoor para tiendas: mapa, cámara AR y recorrido por destinos.  
Este paquete es **binario** (XCFramework). No incluye código fuente del motor.

**Requisitos:** iOS 17+, Xcode 15+, Swift Package Manager.

---

## Instalación (SPM)

1. Xcode → **File → Add Package Dependencies…**
2. Pega la URL de este repositorio.
3. Elige la versión (tag) y añade el producto **IndoorSDK** a tu target.

```swift
dependencies: [
    .package(url: "https://github.com/Indoorly/Indoorly-iOS.git", from: "1.0.0"),
]
```

### Info.plist de tu app

| Clave | Cuándo |
| --- | --- |
| `NSCameraUsageDescription` | Navegación / levantamiento con cámara |
| `NSMotionUsageDescription` | Rumbo del dispositivo |
| `NSLocationWhenInUseUsageDescription` | Solo si usas filtro de tiendas cercanas (GPS) |

---

## Arranque rápido

El token lo emite el panel Indoorly (**Comercios** → API Token `pk_…` para visitantes).

```swift
import IndoorSDK
import SwiftUI

@main
struct MiApp: App {
    init() {
        Indoorly.initialize(apiToken: "pk_…")
        Indoorly.enableAddMoreStores(false)   // apps de clientes: siempre false
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                // Pantalla propia que presenta Indoorly.navigationView()
                ContentView()
            }
        }
    }
}
```

```swift
// Presentar navegación a pantalla completa
try Indoorly.navigationView(stops: [])   // o IDs de destinos: ["lacteos", "panaderia"]
    .onArrival { place in /* IndoorPlaceInfo */ }
    .onVisitFinished { summary in /* duración, metros, visitados */ }
```

La URL del API de producción va **dentro del SDK**. No la configures en la app.

---

## Tokens

| Tipo | Prefijo | Uso |
| --- | --- | --- |
| API Token (visitantes) | `pk_…` | `Indoorly.initialize` en la app pública |
| Admin Token | `sk_…` | Solo apps internas de staff + `enableAddMoreStores(true)` |

```swift
// App visitante
Indoorly.initialize(apiToken: "pk_…")
Indoorly.enableAddMoreStores(false)

// App staff (registrar / ampliar tienda caminando)
Indoorly.initialize(apiToken: "sk_…")
Indoorly.enableAddMoreStores(true)
try Indoorly.surveyView(venue: .new(name: "Sucursal Centro"))
    .onFinish { venue in }
    .onCancel { }
```

---

## Personalización

### Colores e iconos — `IndoorAppearance`

```swift
var brand = IndoorAppearance(
    accentColor: Color(red: 0.0, green: 0.45, blue: 0.25),   // botones, lista, chips
    arrivalColor: Color(red: 0.13, green: 0.75, blue: 0.38), // llegada / faro
    trailColor: Color(red: 0.13, green: 0.75, blue: 0.38),   // rastro recorrido
    categoryIcons: [
        "lacteos": "cup.and.saucer.fill",
        "farmacia": "cross.case.fill",
    ],
    layout: .withHostBackButton   // o .standard / IndoorLayout custom
)

Indoorly.appearance(brand)
```

Dynamic Type y modo claro/oscuro siguen al sistema.

### Layout del chrome — `IndoorLayout`

Controla banners, minimapa y espacio para tu botón “Atrás” encima del SDK.

```swift
let layout = IndoorLayout(
    topLeadingReserved: 56,   // hueco para back button del host
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

// Atajo si solo necesitas hueco para un back circular:
Indoorly.appearance(IndoorAppearance(layout: .withHostBackButton))
```

| Propiedad | Efecto |
| --- | --- |
| `topLeadingReserved` | No dibuja banners debajo de tu chrome superior-izquierdo |
| `showsManeuverBanner` | Instrucción de giro / distancia |
| `showsTrackingBanner` | Estado de localización AR |
| `showsMiniMap` | Minimapa cuando la cámara está activa |

### Fijar una tienda

```swift
Indoorly.venueID("walmart-demo")   // nil = lista todas las del token
```

### Telemetría de uso

Por defecto el SDK reporta sesiones, llegadas y fallos al servicio Indoorly (panel de analytics).

```swift
Indoorly.telemetry(false)   // opt-out
```

---

## Pantallas propias — `IndoorDirectory`

Si no quieres la UI completa de navegación y solo listar tiendas/destinos:

```swift
let directory = try Indoorly.directory()

let venues = try await directory.venues()
let nearby = try await directory.venues(near: coordinate, radiusMeters: 2_000)
let places = try await directory.places(venueID: "walmart-demo")

// Solo con Admin Token:
try await directory.addPlace(venueID: "walmart-demo", name: "Vinos", category: "licores")
try await directory.updatePlace(venueID: "walmart-demo", placeID: "lacteos", name: "Lácteos")
try await directory.removePlace(venueID: "walmart-demo", placeID: "lacteos")
```

`IndoorPlaceInfo.x` / `.y` están en **metros del plano** de la tienda (no GPS).

### GPS del dispositivo

```swift
let location = IndoorLocation()
location.requestWhenInUse()
location.start()
// location.coordinate / authorization
```

### Capacidades del dispositivo

```swift
let caps = IndoorDeviceCapabilities.current
// caps.supportsWorldTracking, caps.hasLiDAR, caps.supportsSceneDepth
```

LiDAR no activa funciones extra en esta versión; la navegación usa grafo 2D + ARWorldMap.

---

## Configuración avanzada (sin fachada)

Si prefieres no usar `Indoorly.*`:

```swift
let config = IndoorConfiguration(
    serviceURL: Indoorly.productionServiceURL,
    clientToken: "pk_…",
    venueID: "walmart-demo",
    appearance: .standard,
    hostOptions: IndoorHostOptions(allowsSurvey: false)
)
IndoorNavigationView(configuration: config, stops: ["farmacia"])
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

## Errores frecuentes

| Situación | Qué revisar |
| --- | --- |
| 401 / unauthorized | Token vacío, regenerado o `sk_` en app de visitantes por error |
| No hay tiendas | El comercio aún no tiene venues en el panel |
| Cámara no abre | Simulador o dispositivo sin ARWorldTracking; usa preview en mapa |
| Registrar no aparece | Hace falta `sk_…` + `enableAddMoreStores(true)` |

---

## Soporte

Emisión de tokens, tiendas y analytics: panel Indoorly de tu organización.  
Versión del package: tag de este repositorio (SPM).
