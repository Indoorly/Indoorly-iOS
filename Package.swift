// swift-tools-version: 5.9
// Binary-only SPM package. No source code is shipped — only an XCFramework zip.
//
// Maintainer release (from the private Indoor monorepo):
//   scripts/build_xcframework.sh
//   scripts/release_sdk.sh --url "https://github.com/Indoorly/Indoorly-iOS/releases/download/X.Y.Z/IndoorSDK.xcframework.zip" --version X.Y.Z
//   Push Package.swift + README.md to this public repo; upload the zip on the GitHub Release.
import PackageDescription

let version = "1.0.0"
let releaseURL = "https://github.com/Indoorly/Indoorly-iOS/releases/download/\(version)/IndoorSDK.xcframework.zip"
let releaseChecksum = "36858947d418d208f525fd83ef4d19d0f8fd98054d58f3abfbf2e1571b7cc37e"

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
