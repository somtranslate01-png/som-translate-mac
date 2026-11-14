// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SomTranslateMac",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "SomTranslateMac", path: "Sources/SomTranslateMac")
    ]
)
