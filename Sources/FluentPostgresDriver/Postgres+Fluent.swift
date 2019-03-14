import FluentSQL

extension DatabaseID {
    public static var psql: DatabaseID {
        return .init(string: "psql")
    }
}

extension Databases {
    public mutating func postgres(
        config: PostgresConfig,
        poolConfig: ConnectionPoolConfig = .init(),
        as id: DatabaseID = .psql,
        isDefault: Bool = true
    ) {
        let db = PostgresConnectionSource(
            config: config,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfig, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}

extension ConnectionPool: Database where Source.Connection: Database {
    public var eventLoop: EventLoop {
        return self.source.eventLoop
    }
    
    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(schema) }
    }
    
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        return self.withConnection { $0.execute(query, onOutput) }
    }
    
    public func close() -> EventLoopFuture<Void> {
        #warning("TODO: implement connectionPool.close()")
        fatalError("")
    }
    
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.withConnection { conn in
            return closure(conn)
        }
    }
}

extension PostgresError: DatabaseError { }

extension PostgresConnection: Database {
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }
    
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        var sql = SQLQueryConverter().convert(query)
        switch query.action {
        case .create:
            sql = PostgresReturning(sql)
        default: break
        }
        return self.sqlQuery(sql) { row in
            try onOutput(row.fluentOutput)
        }
    }
    
    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.sqlQuery(SQLSchemaConverter().convert(schema)) { row in
            fatalError("unexpected output")
        }
    }
    
    public func close() -> EventLoopFuture<Void> {
        #warning("TODO: implement connectionPool.close()")
        fatalError("")
    }
}

private struct PostgresReturning: SQLExpression {
    let base: SQLExpression
    init(_ base: SQLExpression) {
        self.base = base
    }
    
    func serialize(to serializer: inout SQLSerializer) {
        self.base.serialize(to: &serializer)
        serializer.write(" RETURNING *")
    }
}
