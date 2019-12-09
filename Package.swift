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
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.0.0-beta.2"),
        .package(url: "https://github.com/skelpo/postgres-kit.git", .branch("master")),
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
