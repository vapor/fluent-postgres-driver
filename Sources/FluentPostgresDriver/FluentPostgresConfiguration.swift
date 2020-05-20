extension DatabaseConfigurationFactory {
    public static func postgres(
        url urlString: String,
        maxConnectionsPerEventLoop: Int = 1,
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        tlsConfiguration: TLSConfiguration? = nil
    ) throws -> DatabaseConfigurationFactory {
        guard let url = URL(string: urlString) else {
            throw FluentPostgresError.invalidURL(urlString)
        }
        return try .postgres(
            url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            encoder: encoder,
            decoder: decoder
        )
    }

    public static func postgres(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1,
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        tlsConfiguration: TLSConfiguration? = nil
    ) throws -> DatabaseConfigurationFactory {
        guard var configuration = PostgresConfiguration(url: url) else {
            throw FluentPostgresError.invalidURL(url.absoluteString)
        }
        if let tlsConfiguration = tlsConfiguration {
            configuration.tlsConfiguration = tlsConfiguration
        }
        return .postgres(
            configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
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
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
        )
    }

    public static func postgres(
        configuration: PostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init()
    ) -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory {
            FluentPostgresConfiguration(
                middleware: [],
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
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
    let encoder: PostgresDataEncoder
    let decoder: PostgresDataDecoder

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = PostgresConnectionSource(
            configuration: configuration
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            on: databases.eventLoopGroup
        )
        return _FluentPostgresDriver(
            pool: pool,
            encoder: encoder,
            decoder: decoder
        )
    }
}
