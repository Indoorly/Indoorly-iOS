// swift-tools-version: 5.9
// Binary-only SPM package. No source code is shipped — only an XCFramework zip.
//
// Publish from the private monorepo: scripts/publish_sdk.sh
import PackageDescription

let version = "1.1.4"
let releaseURL = "https://github.com/Indoorly/Indoorly-iOS/releases/download/\(version)/IndoorSDK.xcframework.zip"
let releaseChecksum = "e06bf9997e7d4b5b392f103948ea848fb13807f2a5797a40c3abe3869b1f3d8b"

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
