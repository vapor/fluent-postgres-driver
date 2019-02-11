// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "fluent-postgres-driver",
    products: [
        // Swift ORM for PostgreSQL (built on top of Fluent ORM framework)
        .library(name: "FluentPostgresDriver", targets: ["FluentPostgresDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("master")),
        .package(url: "https://github.com/vapor/postgresql.git", .branch("2")),
    ],
    targets: [
        .target(name: "FluentPostgresDriver", dependencies: ["FluentKit", "FluentSQL", "PostgresKit"]),
        .testTarget(name: "FluentPostgresDriverTests", dependencies: ["FluentBenchmark", "FluentPostgresDriver"]),
    ]
)
