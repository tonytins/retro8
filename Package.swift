// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Retro8",
    products: [
        .executable(name: "retro8", targets: ["Retro8"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/tonytins/raylib-swift", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Retro8",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Raylib", package: "raylib-swift"),
            ],
            resources: [
                .copy("Resources/logo.png"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v6]
)