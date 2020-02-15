import FluentSQL

struct _FluentPostgresDatabase {
    let database: PostgresDatabase
    let context: DatabaseContext

    let encoder: PostgresDataEncoder
    let decoder: PostgresDataDecoder
}

extension _FluentPostgresDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        var expression = SQLQueryConverter(delegate: PostgresConverterDelegate())
            .convert(query)
        switch query.action {
        case .create:
            expression = PostgresReturningKey(key: query.idKey, base: expression)
        default: break
        }
        let (sql, binds) = self.serialize(expression)
        do {
            return try self.query(sql, binds.map { try self.encoder.encode($0) }) {
                onRow($0.databaseRow(using: self.decoder))
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
            return try self.query(sql, binds.map { try self.encoder.encode($0) }) {
                fatalError("unexpected row: \($0)")
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }

    func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection { conn in
            conn.simpleQuery("BEGIN").flatMap { _ in
                let db = _FluentPostgresDatabase(
                    database: conn,
                    context: self.context,
                    encoder: self.encoder,
                    decoder: self.decoder
                )
                return closure(db).flatMap { result in
                    conn.simpleQuery("COMMIT").map { _ in
                        result
                    }
                }.flatMapError { error in
                    conn.simpleQuery("ROLLBACK").flatMapThrowing { _ in
                        throw error
                    }
                }
            }
        }
    }
    
    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection {
            closure(_FluentPostgresDatabase(database: $0, context: self.context, encoder: self.encoder, decoder: self.decoder))
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
        self.sql(encoder: encoder, decoder: decoder).execute(sql: query, onRow)
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

private struct PostgresReturningKey: SQLExpression {
    let key: String
    let base: SQLExpression

    func serialize(to serializer: inout SQLSerializer) {
        serializer.statement {
            $0.append(self.base)
            $0.append("RETURNING")
            $0.append(SQLIdentifier(self.key))
        }
    }
}
