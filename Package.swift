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
        .executable(
            name: "Zork1",
            targets: ["Zork1"]
        ),
        .executable(
            name: "GnustoAutoWiringTool",
            targets: ["GnustoAutoWiringTool"]
        ),
        .plugin(
            name: "GnustoAutoWiringPlugin",
            targets: ["GnustoAutoWiringPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"602.0.0"),
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
            path: "Executables/CloakOfDarkness"
        ),
        .executableTarget(
            name: "FrobozzMagicDemoKit",
            dependencies: ["GnustoEngine"],
            path: "Executables/FrobozzMagicDemoKit"
        ),
        .executableTarget(
            name: "Zork1",
            dependencies: ["GnustoEngine"],
            path: "Executables/Zork1"
        ),
        .executableTarget(
            name: "GnustoAutoWiringTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
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
        .testTarget(
            name: "GnustoAutoWiringToolTests",
            dependencies: [
                "GnustoEngine",
                "GnustoAutoWiringTool",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
    ]
)
