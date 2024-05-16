// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "fluent-postgres-driver",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "FluentPostgresDriver", targets: ["FluentPostgresDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.19.0"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.48.4"),
        .package(url: "https://github.com/vapor/postgres-kit.git", from: "2.13.4"),
    ],
    targets: [
        .target(
            name: "FluentPostgresDriver",
            dependencies: [
                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "FluentSQL", package: "fluent-kit"),
                .product(name: "PostgresKit", package: "postgres-kit"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FluentPostgresDriverTests",
            dependencies: [
                .product(name: "FluentBenchmark", package: "fluent-kit"),
                .target(name: "FluentPostgresDriver"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
] }
