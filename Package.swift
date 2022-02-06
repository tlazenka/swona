// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swona",
    products: [
        .library(
            name: "Swona",
            targets: ["Swona"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Swona",
            dependencies: []
        ),
        .testTarget(
            name: "SwonaTests",
            dependencies: ["Swona"]
        ),
    ]
)
