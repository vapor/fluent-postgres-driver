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
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        var expression = SQLQueryConverter(delegate: PostgresConverterDelegate()).convert(query)

        /// For `.create` query actions, we want to return the generated IDs, unless the `customIDKey` is the
        /// empty string, which we use as a very hacky signal for "we don't implement this for composite IDs yet".
        if case .create = query.action, query.customIDKey != .some(.string("")) {
            expression = SQLKit.SQLList([expression, SQLReturning(.init((query.customIDKey ?? .id).description))], separator: SQLRaw(" "))
        }

        return self.execute(sql: expression, { onOutput($0.databaseOutput()) })
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: PostgresConverterDelegate()).convert(schema)

        return self.execute(
            sql: expression,
            // N.B.: Don't fatalError() here; what're users supposed to do about it?
            { self.logger.debug("Unexpected row returned from schema query: \($0)") }
        )
    }

    func execute(enum e: DatabaseEnum) -> EventLoopFuture<Void> {
        switch e.action {
        case .create:
            return e.createCases.reduce(self.create(enum: e.name)) { $0.value($1) }.run()
        case .update:
            if !e.deleteCases.isEmpty {
                self.logger.debug("PostgreSQL does not support deleting enum cases.")
            }
            guard !e.createCases.isEmpty else {
                return self.eventLoop.makeSucceededFuture(())
            }

            return self.eventLoop.flatten(
                e.createCases.map { create in
                    self.alter(enum: e.name).add(value: create).run()
                }
            )
        case .delete:
            return self.drop(enum: e.name).run()
        }
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
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
        self.withConnection { (underlying: any PostgresDatabase) in
            closure(
                _FluentPostgresDatabase(
                    database: underlying.sql(
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
