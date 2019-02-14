import FluentSQL

extension FluentDatabaseID {
    public static var psql: FluentDatabaseID {
        return .init(string: "psql")
    }
}

extension FluentDatabases {
    public mutating func postgres(
        config: PostgresDatabase.Config,
        poolConfig: ConnectionPoolConfig = .init(),
        as id: FluentDatabaseID = .psql,
        isDefault: Bool = true
    ) {
        let driver = PostgresDriver(connectionPool: .init(
            config: poolConfig,
            source: .init(config: config, on: self.eventLoop)
        ))
        self.add(driver, as: id, isDefault: isDefault)
    }
}

public struct PostgresDriver: FluentDatabase {
    public var eventLoop: EventLoop {
        return self.connectionPool.source.eventLoop
    }
    
    public let connectionPool: ConnectionPool<PostgresDatabase>
    
    public init(connectionPool: ConnectionPool<PostgresDatabase>) {
        self.connectionPool = connectionPool
    }
    
    public func execute(_ query: FluentQuery, _ onOutput: @escaping (FluentOutput) throws -> ()) -> EventLoopFuture<Void> {
        return connectionPool.withConnection { connection in
            var sql = SQLQueryConverter().convert(query)
            switch query.action {
            case .create:
                sql = PostgresReturning(sql)
            default: break
            }
            return connection.sqlQuery(sql) { row in
                try onOutput(row.fluentOutput)
            }
        }
    }
    
    public func execute(_ schema: FluentSchema) -> EventLoopFuture<Void> {
        return self.connectionPool.withConnection { connection in
            return connection.sqlQuery(SQLSchemaConverter().convert(schema)) { row in
                fatalError("unexpected output")
            }
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
