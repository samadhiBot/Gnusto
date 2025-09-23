// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Gnusto",
    platforms: [
        .macOS(.v13),
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
        ),
        .library(
            name: "GnustoTestSupport",
            targets: ["GnustoTestSupport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.4"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.6.1"),
        .package(url: "https://github.com/simplydanny/swiftlintplugins", from: "0.61.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..."602.0.0"),
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
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .executableTarget(
            name: "CloakOfDarkness",
            dependencies: ["GnustoEngine"],
            path: "Executables/CloakOfDarkness",
            plugins: [
                "GnustoAutoWiringPlugin",
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .executableTarget(
            name: "FrobozzMagicDemoKit",
            dependencies: ["GnustoEngine"],
            path: "Executables/FrobozzMagicDemoKit",
            exclude: ["README.md", "Docs/"],
            plugins: [
                "GnustoAutoWiringPlugin",
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .executableTarget(
            name: "Zork1",
            dependencies: ["GnustoEngine"],
            path: "Executables/Zork1",
            exclude: ["README.md"],
            plugins: [
                "GnustoAutoWiringPlugin",
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
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
        .target(
            name: "GnustoTestSupport",
            dependencies: [
                "GnustoEngine",
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "CloakOfDarknessTests",
            dependencies: [
                "CloakOfDarkness",
                "GnustoTestSupport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
        ),
        .testTarget(
            name: "FrobozzMagicDemoKitTests",
            dependencies: [
                "FrobozzMagicDemoKit",
                "GnustoTestSupport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
        ),
        .testTarget(
            name: "GnustoEngineTests",
            dependencies: [
                "GnustoEngine",
                "GnustoTestSupport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
        ),
        .testTarget(
            name: "GnustoAutoWiringToolTests",
            dependencies: [
                "GnustoEngine",
                "GnustoAutoWiringTool",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .testTarget(
            name: "Zork1Tests",
            dependencies: [
                "Zork1",
                "GnustoTestSupport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
        ),
    ]
)
