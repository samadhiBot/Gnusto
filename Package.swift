// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Gnusto",
    platforms: [
        .macOS(.v13),
        // .iOS(.v16)
    ],
    products: [
        .library(
            name: "GnustoEngine",
            targets: ["GnustoEngine"]
        ),
        .executable(
            name: "CloakOfDarkness",
            targets: ["CloakOfDarkness"]
        ),
        .executable(
            name: "FrobozzMagicDemoKit",
            targets: ["FrobozzMagicDemoKit"]
        ),
        .plugin(
            name: "GnustoAutoWiringPlugin",
            targets: ["GnustoAutoWiringPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "GnustoEngine",
            dependencies: [
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .executableTarget(
            name: "CloakOfDarkness",
            dependencies: ["GnustoEngine"],
            path: "Executables/CloakOfDarkness",
            plugins: ["GnustoAutoWiringPlugin"]
        ),
        .executableTarget(
            name: "FrobozzMagicDemoKit",
            dependencies: ["GnustoEngine"],
            path: "Executables/FrobozzMagicDemoKit",
            plugins: ["GnustoAutoWiringPlugin"]
        ),
        .executableTarget(
            name: "GnustoAutoWiringTool",
            path: "Sources/GnustoAutoWiringTool"
        ),
        .plugin(
            name: "GnustoAutoWiringPlugin",
            capability: .buildTool(),
            dependencies: ["GnustoAutoWiringTool"]
        ),
        .testTarget(
            name: "GnustoEngineTests",
            dependencies: [
                "GnustoEngine",
                "CloakOfDarkness",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
    ]
)
