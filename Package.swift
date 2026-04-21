// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EveryTerm",
    defaultLocalization: "en",
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
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.0"),
    ],
    targets: [
        // MVP 범위 외: v2.0에서 활성화 예정
        // MARK: - FreeRDP / LibVNCClient binary targets (placeholder)
        //
        // The RDP and VNC adapters currently ship as stubs. Once the
        // Scripts/build-freerdp.sh and Scripts/build-libvncclient.sh
        // pipelines produce signed XCFrameworks and an artifact URL is
        // available, uncomment the corresponding binaryTarget entries and
        // add them to the EveryTerm target dependencies.
        //
        // .binaryTarget(
        //     name: "FreeRDP",
        //     url: "https://example.com/frameworks/FreeRDP-<version>.xcframework.zip",
        //     checksum: "<sha256-hex>"
        // ),
        // .binaryTarget(
        //     name: "LibVNCClient",
        //     url: "https://example.com/frameworks/LibVNCClient-<version>.xcframework.zip",
        //     checksum: "<sha256-hex>"
        // ),
        .target(
            name: "EveryTerm",
            dependencies: [
                .product(name: "Citadel", package: "Citadel"),
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Sparkle", package: "Sparkle"),
                // TODO: add binary targets once XCFrameworks are published:
                // "FreeRDP",
                // "LibVNCClient",
            ],
            path: "Sources/EveryTerm",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "EveryTermApp",
            dependencies: [
                "EveryTerm",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/EveryTermApp"
        ),
        .testTarget(
            name: "EveryTermTests",
            dependencies: ["EveryTerm"],
            path: "Tests/EveryTermTests",
            resources: [
                .copy("Resources/Dracula.itermcolors")
            ]
        )
    ]
)
