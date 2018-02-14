// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "FluentPostgreSQL",
    products: [
        // Swift ORM for PostgreSQL (built on top of Fluent ORM framework)
        .library(name: "FluentPostgreSQL", targets: ["FluentPostgreSQL"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", .exact("1.0.0-beta.1")),

        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .exact("3.0.0-beta.1")),

        // Swift ORM framework (queries, models, and relations) for building NoSQL and SQL database integrations.
        .package(url: "https://github.com/vapor/fluent.git", .exact("3.0.0-beta.2")),

        // Pure Swift, async/non-blocking client for PostgreSQL.
        .package(url: "https://github.com/vapor/postgresql.git", .exact("1.0.0-beta.2")),
    ],
    targets: [
        .target(name: "FluentPostgreSQL", dependencies: ["Async", "CodableKit", "Fluent", "FluentSQL", "PostgreSQL"]),
        .testTarget(name: "FluentPostgreSQLTests", dependencies: ["FluentBenchmark", "FluentPostgreSQL"]),
    ]
)
