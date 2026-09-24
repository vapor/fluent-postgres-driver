import FluentKit
import FluentPostgresDriver
import FluentSQL
import Logging
import PostgresKit
import SQLKit
import PostgresNIO
import ServiceLifecycle

enum TestDriver: Sendable, CaseIterable {
    case asyncKit
    case postgresClient
    case externalPostgresClient

    static var allCases: [TestDriver] {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            [.asyncKit, .postgresClient, .externalPostgresClient]
        } else {
            [.asyncKit]
        }
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static var clientDrivers: [TestDriver] {
        [.postgresClient, .externalPostgresClient]
    }
}

func withDbs(_ driver: TestDriver, _ closure: @escaping @Sendable (_ dbs: Databases, _ db: any Database) async throws -> Void) async throws {
    let databases = Databases(threadPool: .singleton, on: MultiThreadedEventLoopGroup.singleton)

    var externalCleanup: @Sendable () async -> Void = {}

    switch driver {
    case .asyncKit:
        databases.use(.testPostgres(subconfig: "A"), as: .a)
        databases.use(.testPostgres(subconfig: "B"), as: .b)
    case .postgresClient:
        databases.use(.testPostgres(clientSubconfig: "A", logger: .init(label: "test.fluent.a")), as: .a)
        databases.use(.testPostgres(clientSubconfig: "B", logger: .init(label: "test.fluent.b")), as: .b)
    case .externalPostgresClient:
        guard #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) else {
            preconditionFailure("TestDriver.allCases must not include .externalPostgresClient on this platform")
        }
        let clientA = PostgresClient(
            configuration: .test(subconfig: "A"),
            eventLoopGroup: databases.eventLoopGroup,
            backgroundLogger: .init(label: "test.postgres.client.a")
        )
        let clientB = PostgresClient(
            configuration: .test(subconfig: "B"),
            eventLoopGroup: databases.eventLoopGroup,
            backgroundLogger: .init(label: "test.postgres.client.b")
        )

        let serviceGroup = ServiceGroup(services: [clientA, clientB], logger: .init(label: "test.postgres.service-group"))
        let runTask = Task { try await serviceGroup.run() }
        externalCleanup = {
            await serviceGroup.triggerGracefulShutdown()
            _ = try? await runTask.value
        }

        databases.use(.postgres(client: clientA, logger: .init(label: "test.fluent.a")), as: .a)
        databases.use(.postgres(client: clientB, logger: .init(label: "test.fluent.b")), as: .b)
    }

    do {
        let a = databases.database(.a, logger: .init(label: "test.fluent.a"), on: databases.eventLoopGroup.any())!
        _ = try await (a as! any SQLDatabase).raw("drop schema if exists public cascade").run()
        _ = try await (a as! any SQLDatabase).raw("create schema public").run()

        let b = databases.database(.b, logger: .init(label: "test.fluent.b"), on: databases.eventLoopGroup.any())!
        _ = try await (b as! any SQLDatabase).raw("drop schema if exists public cascade").run()
        _ = try await (b as! any SQLDatabase).raw("create schema public").run()

        try await closure(databases, a)
        await databases.shutdownAsync()
        await externalCleanup()
    } catch {
        print(String(reflecting: error))
        await databases.shutdownAsync()
        await externalCleanup()
        throw error
    }
}

extension DatabaseConfigurationFactory {
    static func testPostgres(
        subconfig: String,
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default
    ) -> Self {
        let baseSubconfig = SQLPostgresConfiguration(
            hostname: env("POSTGRES_HOSTNAME_\(subconfig)") ?? env("POSTGRES_HOSTNAME_A") ?? env("POSTGRES_HOSTNAME") ?? "localhost",
            port:    (env("POSTGRES_PORT_\(subconfig)")     ?? env("POSTGRES_PORT_A")     ?? env("POSTGRES_PORT")).flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: env("POSTGRES_USER_\(subconfig)")     ?? env("POSTGRES_USER_A")     ?? env("POSTGRES_USER") ?? "test_username",
            password: env("POSTGRES_PASSWORD_\(subconfig)") ?? env("POSTGRES_PASSWORD_A") ?? env("POSTGRES_PASSWORD") ?? "test_password",
            database: env("POSTGRES_DB_\(subconfig)")       ?? env("POSTGRES_DB_A")       ?? env("POSTGRES_DB") ?? "test_database_\(subconfig.lowercased())",
            tls: try! .prefer(.init(configuration: .makeClientConfiguration()))
        )

        return .postgres(
            configuration: baseSubconfig,
            connectionPoolTimeout: .seconds(30),
            pruneInterval: .seconds(30),
            maxIdleTimeBeforePruning: .seconds(60),
            encodingContext: encodingContext,
            decodingContext: decodingContext
        )
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    static func testPostgres(
        clientSubconfig subconfig: String,
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default,
        logger: Logger,
    ) -> Self {
        let baseSubConfig = PostgresClient.Configuration(
            host:     env("POSTGRES_HOSTNAME_\(subconfig)") ?? env("POSTGRES_HOSTNAME_A") ?? env("POSTGRES_HOSTNAME") ?? "localhost",
            port:    (env("POSTGRES_PORT_\(subconfig)")     ?? env("POSTGRES_PORT_A")     ?? env("POSTGRES_PORT")).flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: env("POSTGRES_USER_\(subconfig)")     ?? env("POSTGRES_USER_A")     ?? env("POSTGRES_USER") ?? "test_username",
            password: env("POSTGRES_PASSWORD_\(subconfig)") ?? env("POSTGRES_PASSWORD_A") ?? env("POSTGRES_PASSWORD") ?? "test_password",
            database: env("POSTGRES_DB_\(subconfig)")       ?? env("POSTGRES_DB_A")       ?? env("POSTGRES_DB") ?? "test_database_\(subconfig.lowercased())",
            tls: .prefer(.makeClientConfiguration())
        )

        return .postgres(
            configuration: baseSubConfig,
            encodingContext: encodingContext,
            decodingContext: decodingContext,
            logger: logger
        )
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension PostgresClient.Configuration {
    static func test(subconfig: String) -> Self {
        .init(
            host:     env("POSTGRES_HOSTNAME_\(subconfig)") ?? env("POSTGRES_HOSTNAME_A") ?? env("POSTGRES_HOSTNAME") ?? "localhost",
            port:    (env("POSTGRES_PORT_\(subconfig)")     ?? env("POSTGRES_PORT_A")     ?? env("POSTGRES_PORT")).flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: env("POSTGRES_USER_\(subconfig)")     ?? env("POSTGRES_USER_A")     ?? env("POSTGRES_USER") ?? "test_username",
            password: env("POSTGRES_PASSWORD_\(subconfig)") ?? env("POSTGRES_PASSWORD_A") ?? env("POSTGRES_PASSWORD") ?? "test_password",
            database: env("POSTGRES_DB_\(subconfig)")       ?? env("POSTGRES_DB_A")       ?? env("POSTGRES_DB") ?? "test_database_\(subconfig.lowercased())",
            tls: .prefer(.makeClientConfiguration())
        )
    }
}
