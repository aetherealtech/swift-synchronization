// swift-tools-version: 5.8

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
            dependencies: [],
            swiftSettings: [.concurrencyChecking(.complete)]
        ),
        .testTarget(
            name: "SynchronizationTests",
            dependencies: ["Synchronization"],
            swiftSettings: [.concurrencyChecking(.complete)]
        ),
    ]
)

extension SwiftSetting {
    enum ConcurrencyChecking: String {
        case complete
        case minimal
        case targeted
    }
    
    static func concurrencyChecking(_ setting: ConcurrencyChecking = .minimal) -> Self {
        unsafeFlags([
            "-Xfrontend", "-strict-concurrency=\(setting)",
            "-Xfrontend", "-warn-concurrency",
            "-Xfrontend", "-enable-actor-data-race-checks",
        ])
    }
}
