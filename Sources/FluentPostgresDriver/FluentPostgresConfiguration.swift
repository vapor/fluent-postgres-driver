import AsyncKit
import FluentKit
import Foundation
import Logging
import NIOCore
import PostgresKit
import PostgresNIO

extension DatabaseConfigurationFactory {
    /// Create a PostgreSQL database configuration from a URL string.
    ///
    /// See ``PostgresKit/SQLPostgresConfiguration/init(url:)`` for the allowed URL format.
    ///
    /// - Parameters:
    ///   - urlString: The URL describing the connection, as a string.
    ///   - maxConnectionsPerEventLoop: Maximum number of connections to open per event loop.
    ///   - connectionPoolTimeout: Maximum time to wait for a connection to become available per request.
    ///   - pruneInterval: How often to check for and prune idle database connections. If `nil` (the default),
    ///     no pruning is performed.
    ///   - maxIdleTimeBeforePruning: How long a connection may remain idle before being pruned, if pruning is enabled.
    ///     Defaults to 2 minutes. Ignored if `pruneInterval` is `nil`.
    ///   - encodingContext: Encoding context to use for serializing data.
    ///   - decodingContext: Decoding context to use for deserializing data.
    ///   - sqlLogLevel: Level at which to log SQL queries.
    public static func postgres(
        url urlString: String,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        pruneInterval: TimeAmount? = nil,
        maxIdleTimeBeforePruning: TimeAmount = .seconds(120),
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default,
        sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        .postgres(
            configuration: try .init(url: urlString),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            pruneInterval: pruneInterval,
            maxIdleTimeBeforePruning: maxIdleTimeBeforePruning,
            encodingContext: encodingContext,
            decodingContext: decodingContext,
            sqlLogLevel: sqlLogLevel
        )
    }

    /// Create a PostgreSQL database configuration from a URL.
    ///
    /// See ``PostgresKit/SQLPostgresConfiguration/init(url:)`` for the allowed URL format.
    ///
    /// - Parameters:
    ///   - url: The URL describing the connection.
    ///   - maxConnectionsPerEventLoop: Maximum number of connections to open per event loop.
    ///   - connectionPoolTimeout: Maximum time to wait for a connection to become available per request.
    ///   - pruneInterval: How often to check for and prune idle database connections. If `nil` (the default),
    ///     no pruning is performed.
    ///   - maxIdleTimeBeforePruning: How long a connection may remain idle before being pruned, if pruning is enabled.
    ///     Defaults to 2 minutes. Ignored if `pruneInterval` is `nil`.
    ///   - encodingContext: Encoding context to use for serializing data.
    ///   - decodingContext: Decoding context to use for deserializing data.
    ///   - sqlLogLevel: Level at which to log SQL queries.
    public static func postgres(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        pruneInterval: TimeAmount? = nil,
        maxIdleTimeBeforePruning: TimeAmount = .seconds(120),
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default,
        sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        .postgres(
            configuration: try .init(url: url),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            pruneInterval: pruneInterval,
            maxIdleTimeBeforePruning: maxIdleTimeBeforePruning,
            encodingContext: encodingContext,
            decodingContext: decodingContext,
            sqlLogLevel: sqlLogLevel
        )
    }

    /// Create a PostgreSQL database configuration from lower-level configuration.
    ///
    /// - Parameters:
    ///   - configuration: A ``PostgresKit/SQLPostgresConfiguration`` describing the connection.
    ///   - maxConnectionsPerEventLoop: Maximum number of connections to open per event loop.
    ///   - connectionPoolTimeout: Maximum time to wait for a connection to become available per request.
    ///   - pruneInterval: How often to check for and prune idle database connections. If `nil` (the default),
    ///     no pruning is performed.
    ///   - maxIdleTimeBeforePruning: How long a connection may remain idle before being pruned, if pruning is enabled.
    ///     Defaults to 2 minutes. Ignored if `pruneInterval` is `nil`.
    ///   - encodingContext: Encoding context to use for serializing data.
    ///   - decodingContext: Decoding context to use for deserializing data.
    ///   - sqlLogLevel: Level at which to log SQL queries.
    public static func postgres(
        configuration: SQLPostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        pruneInterval: TimeAmount? = nil,
        maxIdleTimeBeforePruning: TimeAmount = .seconds(120),
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder>,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder>,
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        .init {
            FluentPostgresConfiguration(
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                connectionPoolTimeout: connectionPoolTimeout,
                pruningInterval: pruneInterval,
                maxIdleTimeBeforePruning: maxIdleTimeBeforePruning,
                encodingContext: encodingContext,
                decodingContext: decodingContext,
                sqlLogLevel: sqlLogLevel
            )
        }
    }
}

/// We'd like to just default the context parameters of the "actual" method. Unfortunately, there are a few
/// cases involving the UNIX domain socket initalizer where usage can resolve to either the new
/// `SQLPostgresConfiguration`-based method or the deprecated `PostgresConfiguration`-based method, with no
/// obvious way to disambiguate which to call. Because the context parameters are generic, if they are defaulted,
/// the compiler resolves the ambiguity in favor of the deprecated method (which has no generic parameters).
/// However, by adding the non-defaulted-parameter variant which takes neither context, we've provided a version
/// which has no generic parameters either, which allows the compiler to resolve the ambiguity in favor of
/// the one with better availability (i.e. the one that isn't deprecated).
///
/// Example affected code:
///
///     _ = DatabaseConfigurationFactory.postgres(configuration: .init(unixDomainSocketPath: "", username: ""))
extension DatabaseConfigurationFactory {
    /// ``postgres(configuration:maxConnectionsPerEventLoop:connectionPoolTimeout:pruneInterval:maxIdleTimeBeforePruning:encodingContext:decodingContext:sqlLogLevel:)``
    /// with the `decodingContext` defaulted.
    public static func postgres(
        configuration: SQLPostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        pruneInterval: TimeAmount? = nil,
        maxIdleTimeBeforePruning: TimeAmount = .seconds(120),
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder>,
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        .postgres(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            pruneInterval: pruneInterval,
            maxIdleTimeBeforePruning: maxIdleTimeBeforePruning,
            encodingContext: encodingContext,
            decodingContext: .default,
            sqlLogLevel: sqlLogLevel
        )
    }

    /// ``postgres(configuration:maxConnectionsPerEventLoop:connectionPoolTimeout:pruneInterval:maxIdleTimeBeforePruning:encodingContext:decodingContext:sqlLogLevel:)``
    /// with the `encodingContext` defaulted.
    public static func postgres(
        configuration: SQLPostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        pruneInterval: TimeAmount? = nil,
        maxIdleTimeBeforePruning: TimeAmount = .seconds(120),
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder>,
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        .postgres(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            pruneInterval: pruneInterval,
            maxIdleTimeBeforePruning: maxIdleTimeBeforePruning,
            encodingContext: .default,
            decodingContext: decodingContext,
            sqlLogLevel: sqlLogLevel
        )
    }

    /// ``postgres(configuration:maxConnectionsPerEventLoop:connectionPoolTimeout:pruneInterval:maxIdleTimeBeforePruning:encodingContext:decodingContext:sqlLogLevel:)``
    /// with both `encodingContext` and `decodingContext` defaulted.
    public static func postgres(
        configuration: SQLPostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        pruneInterval: TimeAmount? = nil,
        maxIdleTimeBeforePruning: TimeAmount = .seconds(120),
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        .postgres(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            pruneInterval: pruneInterval,
            maxIdleTimeBeforePruning: maxIdleTimeBeforePruning,
            encodingContext: .default,
            decodingContext: .default,
            sqlLogLevel: sqlLogLevel
        )
    }
}

/// The actual concrete configuration type produced by a configuration factory.
struct FluentPostgresConfiguration<E: PostgresJSONEncoder, D: PostgresJSONDecoder>: DatabaseConfiguration {
    var middleware: [any AnyModelMiddleware] = []
    fileprivate let configuration: SQLPostgresConfiguration
    let maxConnectionsPerEventLoop: Int
    let connectionPoolTimeout: TimeAmount
    let pruningInterval: TimeAmount?
    let maxIdleTimeBeforePruning: TimeAmount
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let sqlLogLevel: Logger.Level

    func makeDriver(for databases: Databases) -> any DatabaseDriver {
        let connectionSource = PostgresConnectionSource(sqlConfiguration: self.configuration)
        let elgPool = EventLoopGroupConnectionPool(
            source: connectionSource,
            maxConnectionsPerEventLoop: self.maxConnectionsPerEventLoop,
            requestTimeout: self.connectionPoolTimeout,
            pruneInterval: self.pruningInterval,
            maxIdleTimeBeforePruning: self.maxIdleTimeBeforePruning,
            on: databases.eventLoopGroup
        )

        return _FluentPostgresDriver(
            pool: elgPool,
            encodingContext: self.encodingContext,
            decodingContext: self.decodingContext,
            sqlLogLevel: self.sqlLogLevel
        )
    }
}
