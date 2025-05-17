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
//        .executable(
//            name: "FrobozzMagicDemoKit",
//            targets: ["FrobozzMagicDemoKit"]
//        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "GnustoEngine",
            dependencies: [
                .product(name: "CustomDump", package: "swift-custom-dump"),
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
//        .executableTarget(
//            name: "FrobozzMagicDemoKit",
//            dependencies: ["GnustoEngine"],
//            path: "Executables/FrobozzMagicDemoKit"
//        ),
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
