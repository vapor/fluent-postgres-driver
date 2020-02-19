extension DatabaseConfigurationFactory {
    public static func postgres(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1
    ) throws -> DatabaseConfigurationFactory {
        guard let configuration = PostgresConfiguration(url: url) else {
            throw FluentPostgresError.invalidURL(url)
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
        maxConnectionsPerEventLoop: Int = 1
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
        maxConnectionsPerEventLoop: Int = 1
    ) -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory {
            FluentPostgresConfiguration(
                middleware: [],
                configuration: configuration,
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop
            )
        }
    }
}

struct FluentPostgresConfiguration: DatabaseConfiguration {
    var middleware: [AnyModelMiddleware]
    let configuration: PostgresConfiguration
    let maxConnectionsPerEventLoop: Int

    func makeDriver(for databases: Databases) -> DatabaseDriver {
        let db = PostgresConnectionSource(
            configuration: configuration
        )
        let pool = EventLoopGroupConnectionPool(
            source: db,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            on: databases.eventLoopGroup
        )
        return _FluentPostgresDriver(pool: pool)
    }


}

enum FluentPostgresError: Error {
    case invalidURL(URL)
}

struct _FluentPostgresDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>
    
    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }
    
    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentPostgresDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            context: context,
            encoder: self.pool.source.configuration.encoder,
            decoder: self.pool.source.configuration.decoder
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
