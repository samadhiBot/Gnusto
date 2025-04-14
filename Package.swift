// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Gnusto",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "Gnusto",
            targets: ["Gnusto"]
        ),
        .library(
            name: "Nitfol",
            targets: ["Nitfol"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Gloth",
            dependencies: [
                "Files",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "Gnusto",
            dependencies: ["Nitfol"]
        ),
        .target(
            name: "Nitfol",
            dependencies: [],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "GnustoTests",
            dependencies: [
                "Gnusto",
                "Nitfol",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .testTarget(
            name: "NitfolTests",
            dependencies: [
                "Nitfol",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
    ]
)
