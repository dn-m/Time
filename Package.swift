// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Time",
    products: [
        .library(name: "Time", targets: ["Time"]),
        .library(name: "Timeline", targets: ["Timeline"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dn-m/Structure", from: "0.23.0"),
        .package(url: "https://github.com/dn-m/Math", from: "0.7.0")
    ],
    targets: [

        // Sources
        .target(name: "Time", dependencies: []),
        .target(name: "Timeline", dependencies: ["DataStructures", "Math", "Time"]),

        // Tests
        .testTarget(name: "TimelineTests", dependencies: ["Timeline"]),
    ]
)
