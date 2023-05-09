import AsyncKit
import NIOCore
import Logging
import FluentKit
import PostgresKit

struct _FluentPostgresDriver<E: PostgresJSONEncoder, D: PostgresJSONDecoder>: DatabaseDriver {
    let pool: EventLoopGroupConnectionPool<PostgresConnectionSource>
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let sqlLogLevel: Logger.Level
    
    func makeDatabase(with context: DatabaseContext) -> any Database {
        _FluentPostgresDatabase(
            database: self.pool
                .pool(for: context.eventLoop)
                .database(logger: context.logger)
                .sql(encodingContext: self.encodingContext, decodingContext: self.decodingContext, queryLogLevel: self.sqlLogLevel),
            context: context,
            encodingContext: self.encodingContext,
            decodingContext: self.decodingContext,
            inTransaction: false
        )
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}
