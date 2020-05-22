// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Repl",
    dependencies: [
		.package(path: "../Swona"),
		.package(name: "LineNoise", url: "https://github.com/andybest/linenoise-swift.git", .exact("0.0.3")),
    ],
    targets: [
        .target(
            name: "Repl",
            dependencies: ["Swona", "LineNoise"]),
    ]
)
