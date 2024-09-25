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
    dependencies: [],
    targets: [
        .target(
            name: "Synchronization",
            dependencies: []
        ),
        .testTarget(
            name: "SynchronizationTests",
            dependencies: ["Synchronization"]
        ),
    ]
)
