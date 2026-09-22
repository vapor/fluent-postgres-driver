import FluentKit
import FluentSQL
import Logging
import PostgresKit
import PostgresNIO

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct _FluentPostgresClientDatabase<E: PostgresJSONEncoder, D: PostgresJSONDecoder> {
    enum Source {
        case client(PostgresClient)
        case connection(any SQLDatabase)
    }

    let source: Source
    let context: DatabaseContext
    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let inTransaction: Bool
    let sqlLogLevel: Logger.Level

    func with(inTransaction: Bool) -> Self {
        .init(
            source: source, 
            context: context, 
            encodingContext: encodingContext, 
            decodingContext: decodingContext, 
            inTransaction: inTransaction, 
            sqlLogLevel: sqlLogLevel
        )
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FluentPostgresClientDatabase: Database {
    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        switch self.source {
        case .connection:
            return closure(self)
        case .client(let client):
            return self.eventLoop.makeFutureWithUnsafeTask {
                try await client.withConnection { connection in
                    try await closure(self.scoped(to: connection, inTransaction: self.inTransaction)).unsafeGet()
                }
            }
        }
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        guard !self.inTransaction else {
            return closure(self)
        }

        @Sendable
        func runTransaction(on db: Self) async throws -> T {
            try await db.raw("BEGIN").run()
            do {
                let result = try await closure(db).unsafeGet()
                try await db.raw("COMMIT").run()
                return result
            } catch {
                try await db.raw("ROLLBACK").run()
                throw error
            }
        }

        switch self.source {
        case .connection:
            return self.eventLoop.makeFutureWithUnsafeTask {
                try await runTransaction(on: self.with(inTransaction: true))
            }
        case .client(let client):
            return self.eventLoop.makeFutureWithUnsafeTask {
                try await client.withConnection { connection in
                    try await runTransaction(on: self.scoped(to: connection, inTransaction: true))
                }
            }
        }
    }

    func withSession<R>(_ closure: @escaping (any SQLDatabase) async throws -> R) async throws -> R {
        switch self.source {
        case .connection:
            try await closure(self)
        case .client(let client):
            try await client.withConnection { connection in
                try await closure(self.scoped(to: connection))
            }
        }
    }

    private func scoped(to conn: PostgresConnection, inTransaction: Bool? = nil) -> Self {
        .init(
            source: .connection(
                conn
                    .logging(to: self.logger)
                    .sql(
                        encodingContext: self.encodingContext,
                        decodingContext: self.decodingContext,
                        queryLogLevel: self.sqlLogLevel)),
            context: self.context,
            encodingContext: self.encodingContext,
            decodingContext: self.decodingContext,
            inTransaction: inTransaction ?? self.inTransaction,
            sqlLogLevel: self.sqlLogLevel
        )
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FluentPostgresClientDatabase: SQLDatabase {
    var version: (any SQLDatabaseReportedVersion)? { nil }
    var dialect: any SQLDialect { PostgresDialect() }
    var queryLogLevel: Logger.Level? { self.sqlLogLevel }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> Void) async throws {
        switch self.source {
        case .connection(let connection):
            try await connection.execute(sql: query, onRow)

        case .client(let client):
            try await client.withConnection { connection in
                try await self.scoped(to: connection).execute(sql: query, onRow)
            }
        }
    }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> Void) -> EventLoopFuture<Void> {
        let onRow: @Sendable (any SQLRow) -> Void = { row in
            if self.eventLoop.inEventLoop {
                onRow(row)
            } else {
                self.eventLoop.execute { onRow(row) }
            }
        }

        switch self.source {
        case .connection(let connection):
            return connection.execute(sql: query, onRow).hop(to: self.eventLoop)
        case .client(let client):
            return self.eventLoop.makeFutureWithTask {
                try await client.withConnection { connection in
                    try await self.scoped(to: connection).execute(sql: query, onRow)
                }
            }
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
extension _FluentPostgresClientDatabase: TransactionControlDatabase {
    func beginTransaction() -> EventLoopFuture<Void> {
        // We must be on one connection
        switch self.source {
        case .connection(let db):
            db.raw("BEGIN").run()
        case .client:
            eventLoop.makeFailedFuture(FluentPostgresError.transactionControlRequiresConnection)
        }
    }

    func commitTransaction() -> EventLoopFuture<Void> {
        // We must be on one connection
        switch self.source {
        case .connection(let db):
            db.raw("COMMIT").run()
        case .client:
            eventLoop.makeFailedFuture(FluentPostgresError.transactionControlRequiresConnection)
        }
    }

    func rollbackTransaction() -> EventLoopFuture<Void> {
        // We must be on one connection
        switch self.source {
        case .connection(let db):
            db.raw("ROLLBACK").run()
        case .client:
            eventLoop.makeFailedFuture(FluentPostgresError.transactionControlRequiresConnection)
        }
    }
}
