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
