import Logging
import FluentKit
import AsyncKit
import NIOCore
import NIOSSL
import Foundation
import PostgresKit

extension DatabaseConfigurationFactory {
    public static func postgres(
        url urlString: String,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        guard let url = URL(string: urlString) else {
            throw FluentPostgresError.invalidURL(urlString)
        }
        return try .postgres(
            url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder,
            decoder: decoder,
            sqlLogLevel: sqlLogLevel
        )
    }

    public static func postgres(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        guard let configuration = PostgresConfiguration(url: url) else {
            throw FluentPostgresError.invalidURL(url.absoluteString)
        }
        return .postgres(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            sqlLogLevel: sqlLogLevel
        )
    }

    public static func postgres(
        hostname: String,
        port: Int = PostgresConfiguration.ianaPortNumber,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        return .postgres(
            configuration: .init(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                database: database,
                tlsConfiguration: tlsConfiguration
            ),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            sqlLogLevel: sqlLogLevel
        )
    }

    public static func postgres(
        configuration: PostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory {
            FluentPostgresConfiguration(
                middleware: [],
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                encoder: encoder,
                decoder: decoder,
                sqlLogLevel: sqlLogLevel
            )
        }
    }
}

struct FluentPostgresConfiguration: DatabaseConfiguration {
    var middleware: [AnyModelMiddleware]
    let configuration: PostgresConfiguration
    let maxConnectionsPerEventLoop: Int
    /// The amount of time to wait for a connection from
    /// the connection pool before timing out.
    let connectionPoolTimeout: TimeAmount
    let encoder: PostgresDataEncoder
    let decoder: PostgresDataDecoder
    let sqlLogLevel: Logger.Level

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = PostgresConnectionSource(
            configuration: configuration
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            requestTimeout: connectionPoolTimeout,
            on: databases.eventLoopGroup
        )
        return _FluentPostgresDriver(
            pool: pool,
            encoder: self.encoder,
            decoder: self.decoder,
            sqlLogLevel: self.sqlLogLevel
        )
    }
}
