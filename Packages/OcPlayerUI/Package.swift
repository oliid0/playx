// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "OcPlayerUI",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "OcPlayerUI", targets: ["OcPlayerUI"])],
    targets: [
        .target(name: "OcPlayerUI")
    ]
)
