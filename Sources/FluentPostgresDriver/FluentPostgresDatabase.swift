import FluentSQL

struct _FluentPostgresDatabase {
    let database: PostgresDatabase
    let context: DatabaseContext
}

extension _FluentPostgresDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        var expression = SQLQueryConverter(delegate: PostgresConverterDelegate())
            .convert(query)
        switch query.action {
        case .create:
            expression = PostgresReturning(expression)
        default: break
        }
        let (sql, binds) = self.serialize(expression)
        do {
            return try self.query(sql, binds.map { try PostgresDataEncoder().encode($0) }) {
                fatalError("unexpected row: \($0)")
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: PostgresConverterDelegate())
            .convert(schema)
        let (sql, binds) = self.serialize(expression)
        do {
            return try self.query(sql, binds.map { try PostgresDataEncoder().encode($0) }) {
                fatalError("unexpected row: \($0)")
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentPostgresDatabase(database: $0, context: self.context))
        }
    }
}

extension _FluentPostgresDatabase: SQLDatabase {
    var dialect: SQLDialect {
        PostgresDialect()
    }
    
    public func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.sql().execute(sql: query, onRow)
    }
}

extension _FluentPostgresDatabase: PostgresDatabase {
    func send(_ request: PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.database.send(request, logger: logger)
    }
    
    func withConnection<T>(_ closure: @escaping (PostgresConnection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}

private struct PostgresReturning: SQLExpression {
    let base: SQLExpression
    init(_ base: SQLExpression) {
        self.base = base
    }

    func serialize(to serializer: inout SQLSerializer) {
        self.base.serialize(to: &serializer)
        serializer.write(#" RETURNING id as "fluentID""#)
    }
}
