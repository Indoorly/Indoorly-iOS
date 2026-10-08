// swift-tools-version: 5.9
// Binary-only SPM package. No source code is shipped — only an XCFramework zip.
//
// Publish from the private monorepo: scripts/publish_sdk.sh
import PackageDescription

let version = "1.0.2"
let releaseURL = "https://github.com/Indoorly/Indoorly-iOS/releases/download/\(version)/IndoorSDK.xcframework.zip"
let releaseChecksum = "8d894a7d20288f1e0dbdfcd429b631c929b0c31bb2304a8bcf87f1da80655d7d"

let binary: Target
if let localPath = Context.environment["INDOOR_XCFRAMEWORK"], !localPath.isEmpty {
    binary = .binaryTarget(name: "IndoorSDK", path: localPath)
} else {
    binary = .binaryTarget(name: "IndoorSDK", url: releaseURL, checksum: releaseChecksum)
}

let package = Package(
    name: "IndoorSDK",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "IndoorSDK", targets: ["IndoorSDK"]),
    ],
    targets: [binary]
)
