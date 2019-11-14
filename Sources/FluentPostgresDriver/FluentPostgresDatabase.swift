import FluentSQL

struct _FluentPostgresDatabase {
    let pool: EventLoopConnectionPool<PostgresConnectionSource>
    let context: DatabaseContext
}

extension _FluentPostgresDatabase: Database {
    func execute(query: DatabaseQuery, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        var sql = SQLQueryConverter(delegate: PostgresConverterDelegate())
            .convert(query)
        switch query.action {
        case .create:
            sql = PostgresReturning(sql)
        default: break
        }
        let serialized: (sql: String, binds: [PostgresData])
        do {
            serialized = try postgresSerialize(sql)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .query(serialized.sql, serialized.binds, onRow)
        }
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: PostgresConverterDelegate())
            .convert(schema)
        let serialized: (sql: String, binds: [PostgresData])
        do {
            serialized = try postgresSerialize(sql)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .query(serialized.sql, serialized.binds) {
                    fatalError("unexpected row: \($0)")
                }
        }
    }
}

extension _FluentPostgresDatabase: SQLDatabase {
    public func execute(
        sql query: SQLExpression,
        _ onRow: @escaping (SQLRow) -> ()
    ) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: self.logger) {
            $0.logging(to: self.logger)
                .sql()
                .execute(sql: query, onRow)
        }
    }
}

extension _FluentPostgresDatabase: PostgresDatabase {
    func send(_ request: PostgresRequest, logger: Logger) -> EventLoopFuture<Void> {
        self.pool.withConnection(logger: logger) {
            $0.send(request, logger: logger)
        }
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

private func postgresSerialize(_ sql: SQLExpression) throws -> (String, [PostgresData]) {
    var serializer = SQLSerializer(dialect: PostgresDialect())
    sql.serialize(to: &serializer)
    let binds: [PostgresData]
    binds = try serializer.binds.map { encodable in
        return try PostgresDataEncoder().encode(encodable)
    }
    return (serializer.sql, binds)
}
