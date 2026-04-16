// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EveryTerm",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EveryTerm",
            targets: ["EveryTerm"]
        ),
        .executable(
            name: "EveryTermApp",
            targets: ["EveryTermApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.7.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "EveryTerm",
            dependencies: [
                .product(name: "Citadel", package: "Citadel"),
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/EveryTerm",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "EveryTermApp",
            dependencies: ["EveryTerm"],
            path: "Sources/EveryTermApp"
        ),
        .testTarget(
            name: "EveryTermTests",
            dependencies: ["EveryTerm"],
            path: "Tests/EveryTermTests"
        )
    ]
)
