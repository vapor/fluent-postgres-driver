import AsyncKit
import NIOCore
import Logging
import FluentKit
import PostgresKit

enum FluentPostgresError: Error {
    case invalidURL(String)
}

struct _FluentPostgresDriver: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>
    let encoder: PostgresDataEncoder
    let decoder: PostgresDataDecoder
    let sqlLogLevel: Logger.Level
    
    var eventLoopGroup: EventLoopGroup {
        self.pool.eventLoopGroup
    }
    
    func makeDatabase(with context: DatabaseContext) -> Database {
        _FluentPostgresDatabase(
            database: self.pool.pool(for: context.eventLoop).database(logger: context.logger),
            context: context,
            encoder: self.encoder,
            decoder: self.decoder,
            inTransaction: false,
            sqlLogLevel: self.sqlLogLevel
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
