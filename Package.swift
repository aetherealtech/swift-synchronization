// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Synchronization",
    products: [
        .library(
            name: "Synchronization",
            targets: ["Synchronization"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/aetherealtech/swift-assertions", branch: "master"),
    ],
    targets: [
        .target(
            name: "Synchronization",
            dependencies: []
        ),
        .testTarget(
            name: "SynchronizationTests",
            dependencies: [
                "Synchronization",
                .product(name: "Assertions", package: "swift-assertions"),
            ]
        ),
    ]
)
