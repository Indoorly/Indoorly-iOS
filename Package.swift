// swift-tools-version: 5.9
// Binary-only SPM package. No source code is shipped — only an XCFramework zip.
//
// Publish from the private monorepo: scripts/publish_sdk.sh
import PackageDescription

let version = "1.0.1"
let releaseURL = "https://github.com/Indoorly/Indoorly-iOS/releases/download/\(version)/IndoorSDK.xcframework.zip"
let releaseChecksum = "f7f49a8f54ed228b7a5138d20657e7f8ef799dbd96a28ef3ebfb7ae189172d3f"

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
