import FluentSQL

final class PostgresDatabaseDriver: DatabaseDriver {
    let pool: ConnectionPool<PostgresConnectionSource>
    
    var eventLoopGroup: EventLoopGroup {
        return self.pool.eventLoopGroup
    }
    
    init(pool: ConnectionPool<PostgresConnectionSource>) {
        self.pool = pool
    }
    
    func execute(query: DatabaseQuery, database: Database, onRow: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        var sql = SQLQueryConverter(delegate: PostgresConverterDelegate())
            .convert(query)
        switch query.action {
        case .create:
            sql = PostgresReturning(sql)
        default: break
        }
        return self.pool.withConnection(eventLoop: database.eventLoopPreference.pool) { conn in
            conn.execute(sql: sql) { row in
                onRow(row as! PostgresRow)
            }
        }
    }

    func execute(schema: DatabaseSchema, database: Database) -> EventLoopFuture<Void> {
        let sql = SQLSchemaConverter(delegate: PostgresConverterDelegate())
            .convert(schema)
        return self.pool.withConnection(eventLoop: database.eventLoopPreference.pool) { conn in
            conn.execute(sql: sql) { row in
                fatalError("unexpected output")
            }
        }
    }
    
    func shutdown() {
        self.pool.shutdown()
    }
}

extension PostgresDatabaseDriver: PostgresClient {
    var eventLoop: EventLoop {
        return self.eventLoopGroup.next()
    }
    
    func send(_ request: PostgresRequest) -> EventLoopFuture<Void> {
        return self.pool.withConnection(eventLoop: .indifferent) { $0.send(request) }
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


extension EventLoopPreference {
    var pool: ConnectionPoolEventLoopPreference {
        switch self {
        case .delegate(on: let eventLoop):
            return .delegate(on: eventLoop)
        case .indifferent:
            return .indifferent
        }
    }
}
