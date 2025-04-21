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
        .library(
            name: "CloakOfDarknessGameData",
            targets: ["CloakOfDarknessGameData"]
        ),
        .executable(
            name: "CloakOfDarkness",
            targets: ["CloakOfDarkness"]
        ),
        .executable(
            name: "FrobozzMagicDemoKit",
            targets: ["FrobozzMagicDemoKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GnustoEngine"),
        .target(
            name: "CloakOfDarknessGameData",
            dependencies: ["GnustoEngine"],
            path: "Sources/CloakOfDarknessGameData"
        ),
        .executableTarget(
            name: "CloakOfDarkness",
            dependencies: [
                "GnustoEngine",
                "CloakOfDarknessGameData"
            ],
            path: "Executables/CloakOfDarkness"
        ),
        .executableTarget(
            name: "FrobozzMagicDemoKit",
            dependencies: ["GnustoEngine"],
            path: "Executables/FrobozzMagicDemoKit"
        ),
        .testTarget(
            name: "GnustoEngineTests",
            dependencies: [
                "GnustoEngine",
                "CloakOfDarknessGameData",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
    ]
)
