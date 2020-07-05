extension DatabaseConfigurationFactory {
    public static func postgres(
        url urlString: String,
        maxConnectionsPerEventLoop: Int = 1,
        newConnectionTimeout: NIO.TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init()
    ) throws -> DatabaseConfigurationFactory {
        guard let url = URL(string: urlString) else {
            throw FluentPostgresError.invalidURL(urlString)
        }
        return try .postgres(
            url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            newConnectionTimeout: newConnectionTimeout,
            encoder: encoder,
            decoder: decoder
        )
    }

    public static func postgres(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1,
        newConnectionTimeout: NIO.TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init()
    ) throws -> DatabaseConfigurationFactory {
        guard let configuration = PostgresConfiguration(url: url) else {
            throw FluentPostgresError.invalidURL(url.absoluteString)
        }
        return .postgres(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            newConnectionTimeout: newConnectionTimeout
        )
    }

    public static func postgres(
        hostname: String,
        port: Int = 5432,
        username: String,
        password: String,
        database: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        newConnectionTimeout: NIO.TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init()
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
            newConnectionTimeout: newConnectionTimeout
        )
    }

    public static func postgres(
        configuration: PostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        newConnectionTimeout: NIO.TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init()
    ) -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory {
            FluentPostgresConfiguration(
                middleware: [],
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                newConnectionTimeout: newConnectionTimeout,
                encoder: encoder,
                decoder: decoder
            )
        }
    }
}

struct FluentPostgresConfiguration: DatabaseConfiguration {
    var middleware: [AnyModelMiddleware]
    let configuration: PostgresConfiguration
    let maxConnectionsPerEventLoop: Int
    /// The amount of time to wait for a new connection from
    /// the connection pool before timing out.
    let newConnectionTimeout: NIO.TimeAmount
    let encoder: PostgresDataEncoder
    let decoder: PostgresDataDecoder

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = PostgresConnectionSource(
            configuration: configuration
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            requestTimeout: newConnectionTimeout,
            on: databases.eventLoopGroup
        )
        return _FluentPostgresDriver(
            pool: pool,
            encoder: encoder,
            decoder: decoder
        )
    }
}
