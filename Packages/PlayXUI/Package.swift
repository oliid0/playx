// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PlayXUI",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [.library(name: "PlayXUI", targets: ["PlayXUI"])],
    targets: [
        .target(name: "PlayXUI")
    ]
)
