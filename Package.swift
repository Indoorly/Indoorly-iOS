// swift-tools-version: 5.9
// Binary-only SPM package. No source code is shipped — only an XCFramework zip.
//
// Publish from the private monorepo: scripts/publish_sdk.sh
import PackageDescription

let version = "1.0.4"
let releaseURL = "https://github.com/Indoorly/Indoorly-iOS/releases/download/\(version)/IndoorSDK.xcframework.zip"
let releaseChecksum = "98566e7bd9a5b86297a8afad3288beddebd2005bd06390556c6d8b4f4f975c0c"

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
