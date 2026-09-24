import PostgresNIO
import FluentKit
import Logging

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension DatabaseConfigurationFactory {
    /// Create a PostgreSQL database configuration from a PostgresClient.Configuration.
    /// 
    /// This is different to the other configuration factories as it uses PostgresNIO's
    /// modern PostgresClient connection pool under the hood instead of the AsyncKit pool.
    /// 
    /// > Warning: The database that's returned using this configuration is not castable
    /// > to a `PostgresDatabase`, and `TransactionControlDatabase` is to be used inside 
    /// > `withConnection`.
    ///
    /// - Parameters:
    ///   - configuration: A ``PostgresNIO/PostgresClient/Configuration``.
    ///   - encodingContext: Encoding context to use for serializing data.
    ///   - decodingContext: Decoding context to use for deserializing data.
    ///   - sqlLogLevel: Level at which to log SQL queries.
    ///   - logger: Logger to use in the client.
    public static func postgres(
        configuration: PostgresClient.Configuration,
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default,
        sqlLogLevel: Logger.Level = .debug,
        logger: Logger
    ) -> Self {
        .init {
            FluentPostgresClientConfiguration(
                client: .configuration(configuration),
                encodingContext: encodingContext,
                decodingContext: decodingContext,
                sqlLogLevel: sqlLogLevel,
                logger: logger
            )
        }
    }

    public static func postgres(
        client: PostgresClient,
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default,
        sqlLogLevel: Logger.Level = .debug,
        logger: Logger
    ) -> Self {
        .init {
            FluentPostgresClientConfiguration(
                client: .client(client),
                encodingContext: encodingContext,
                decodingContext: decodingContext,
                sqlLogLevel: sqlLogLevel,
                logger: logger
            )
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
private struct FluentPostgresClientConfiguration<E: PostgresJSONEncoder, D: PostgresJSONDecoder>: DatabaseConfiguration {
    enum Client {
        case client(PostgresClient)
        case configuration(PostgresClient.Configuration)
    }
    
    var middleware: [any AnyModelMiddleware] = []

    let client: Client
    
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let sqlLogLevel: Logger.Level
    let logger: Logger

    func makeDriver(for databases: Databases) -> any DatabaseDriver {
        switch client {
        case .client(let client):
            _FluentPostgresClientDriver<E, D>(
                client: client,
                encodingContext: self.encodingContext,
                decodingContext: self.decodingContext,
                sqlLogLevel: sqlLogLevel,
                logger: logger
            )

        case .configuration(let config):
            _FluentPostgresClientDriver<E, D>(
                configuration: config,
                eventLoopGroup: databases.eventLoopGroup,
                encodingContext: self.encodingContext,
                decodingContext: self.decodingContext,
                sqlLogLevel: sqlLogLevel,
                logger: logger
            )
        }
    }
}
