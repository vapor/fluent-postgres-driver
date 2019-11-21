// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent-postgres-driver",
    products: [
        .library(name: "FluentPostgresDriver", targets: ["FluentPostgresDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skelpo/fluent-kit.git", from: "1.0.0-beta.2.2"),
        .package(url: "https://github.com/skelpo/postgres-kit.git", from: "2.0.0-beta.1.1"),
    ],
    targets: [
        .target(name: "FluentPostgresDriver", dependencies: [
            "FluentKit",
            "FluentSQL",
            "PostgresKit",
        ]),
        .testTarget(name: "FluentPostgresDriverTests", dependencies: [
            "FluentBenchmark",
            "FluentPostgresDriver",
        ]),
    ]
)
