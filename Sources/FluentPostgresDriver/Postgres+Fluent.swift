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

extension ConnectionPool: Database where Source.Connection: SQLDatabase {
    public var eventLoop: EventLoop {
        return self.source.eventLoop
    }
}
extension PostgresConnection: Database { }

extension Database where Self: SQLDatabase {
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
