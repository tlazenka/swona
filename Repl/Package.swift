// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Repl",
    dependencies: [
        .package(name: "Swona", path: "../"),
        .package(name: "LineNoise", url: "https://github.com/andybest/linenoise-swift.git", .exact("0.0.3")),
    ],
    targets: [
        .executableTarget(
            name: "Repl",
            dependencies: ["Swona", "LineNoise"]
        ),
    ]
)
