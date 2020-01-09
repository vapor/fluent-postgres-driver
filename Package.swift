// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fluent-postgres-driver",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "FluentPostgresDriver", targets: ["FluentPostgresDriver"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .branch("empty-set")),
        .package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0-beta.2"),
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
