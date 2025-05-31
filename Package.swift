// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "FloeNet",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FloeNet",
            targets: ["FloeNet"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FloeNet"),
        .testTarget(
            name: "FloeNetTests",
            dependencies: ["FloeNet"]
        ),
    ]
)
