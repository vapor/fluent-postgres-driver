import FluentKit
import FluentSQL
import Logging
import PostgresKit
import PostgresNIO
import SQLKit

struct _FluentPostgresDatabase<E: PostgresJSONEncoder, D: PostgresJSONDecoder> {
    let database: any SQLDatabase
    let context: DatabaseContext
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let inTransaction: Bool
}

extension _FluentPostgresDatabase: Database {
    func transaction<T: Sendable>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        guard !self.inTransaction else {
            return closure(self)
        }
        return self.withConnection { conn in
            guard let sqlConn = conn as? any SQLDatabase else {
                fatalError(
                    """
                    Connection yielded by a Fluent+Postgres database is not also an SQLDatabase.
                    This is a bug in Fluent; please report it at https://github.com/vapor/fluent-postgres-driver/issues
                    """
                )
            }
            return sqlConn.raw("BEGIN").run().flatMap {
                closure(conn).flatMap { result in
                    sqlConn.raw("COMMIT").run().and(value: result).map { $1 }
                }.flatMapError { error in
                    sqlConn.raw("ROLLBACK").run().flatMapThrowing { throw error }
                }
            }
        }
    }

    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.withConnection { (connection: PostgresConnection) in
            closure(
                _FluentPostgresDatabase(
                    database: connection.logging(withConnectionIDTo: self.logger).sql(
                        encodingContext: self.encodingContext,
                        decodingContext: self.decodingContext,
                        queryLogLevel: self.database.queryLogLevel
                    ),
                    context: self.context,
                    encodingContext: self.encodingContext,
                    decodingContext: self.decodingContext,
                    inTransaction: true
                )
            )
        }
    }
}

extension _FluentPostgresDatabase: TransactionControlDatabase {
    func beginTransaction() -> EventLoopFuture<Void> {
        self.raw("BEGIN").run()
    }

    func commitTransaction() -> EventLoopFuture<Void> {
        self.raw("COMMIT").run()
    }

    func rollbackTransaction() -> EventLoopFuture<Void> {
        self.raw("ROLLBACK").run()
    }
}

extension _FluentPostgresDatabase: SQLDatabase {
    var version: (any SQLDatabaseReportedVersion)? { self.database.version }
    var dialect: any SQLDialect { self.database.dialect }
    var queryLogLevel: Logger.Level? { self.database.queryLogLevel }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> Void) -> EventLoopFuture<Void> {
        self.database.execute(sql: query, onRow)
    }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> Void) async throws {
        try await self.database.execute(sql: query, onRow)
    }

    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await self.database.withSession(closure)
    }
}

extension _FluentPostgresDatabase: PostgresDatabase {
    func send(_ request: any PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.withConnection { $0.send(request, logger: logger) }
    }

    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        guard let psqlDb: any PostgresDatabase = self.database as? any PostgresDatabase else {
            fatalError(
                """
                Connection yielded by a Fluent+Postgres database is not also a PostgresDatabase.
                This is a bug in Fluent; please report it at https://github.com/vapor/fluent-postgres-driver/issues
                """
            )
        }

        return psqlDb.withConnection(closure)
    }
}

extension PostgresConnection {
    /// This connection, logging to `logger` with the connection's ID attached, the same way PostgresNIO tags its own logs.
    ///
    /// Only the ID is taken from the connection. The rest of the connection's own logger metadata (such as a request ID)
    /// belongs to whichever request happened to open the connection, so it must not be used for anyone else's queries.
    func logging(withConnectionIDTo logger: Logger) -> any PostgresDatabase {
        var logger = logger
        logger[metadataKey: "psql_connection_id"] = "\(self.id)"
        return self.logging(to: logger)
    }
}
