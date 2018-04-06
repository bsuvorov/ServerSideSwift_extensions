// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ServerSideSwiftExtensions",
    products: [
        .library(name: "ServerSideSwiftExtensions", targets: ["ServerSideSwiftExtensions"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/vapor/fluent-provider.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/czechboy0/Jay.git", .upToNextMajor(from: "1.0.1")),
    ],
    targets: [
        .target(
            name: "ServerSideSwiftExtensions",
            dependencies: ["Vapor", "FluentProvider", "Jay"]
        )
    ]
)

