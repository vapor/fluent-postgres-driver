extension DatabaseDriverFactory {
    public static func postgres(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1
    ) throws -> DatabaseDriverFactory {
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
    ) -> DatabaseDriverFactory {
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
    ) -> DatabaseDriverFactory {
        return DatabaseDriverFactory { databases in
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
            context: context
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
