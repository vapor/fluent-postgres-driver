import FluentSQL

#warning("TODO: fix to allow conformance")
struct SQLOutput: FluentOutput {
    let row: SQLRow
    
    var description: String {
        return "\(self.row)"
    }
    
    public init(row: SQLRow) {
        self.row = row
    }
    
    func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.row.decode(column: field, as: T.self)
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
                let output = SQLOutput(row: row)
                try onOutput(output)
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
