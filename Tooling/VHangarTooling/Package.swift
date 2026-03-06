// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VHangarTooling",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "VHangarTooling", targets: ["VHangarTooling"])
    ],
    targets: [
        .target(
            name: "VHangarTooling",
            path: "Sources"
        ),
        .testTarget(
            name: "VHangarToolingTests",
            dependencies: ["VHangarTooling"],
            path: "Tests"
        )
    ]
)

