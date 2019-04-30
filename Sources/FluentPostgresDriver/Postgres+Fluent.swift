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
    
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return self.withConnection { conn in
            return closure(conn)
        }
    }
}

extension PostgresError: DatabaseError { }

struct PostgresConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .uuid: return SQLRaw("UUID")
        default: return nil
        }
    }
    
    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        return SQLRaw("\(column)->>'\(path[0])'")
    }
}

extension PostgresConnection: Database {
    public func transaction<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        return closure(self)
    }
    
    public func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
        var sql = SQLQueryConverter(delegate: PostgresConverterDelegate()).convert(query)
        switch query.action {
        case .create:
            sql = PostgresReturning(sql)
        default: break
        }
        var serializer = SQLSerializer(dialect: PostgresDialect())
        sql.serialize(to: &serializer)
        return try! self.query(serializer.sql, serializer.binds.map { encodable in
            return try PostgresDataEncoder().encode(encodable)
        }) { row in
            try onOutput(row)
        }
    }
    
    public func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
        return self.sqlQuery(SQLSchemaConverter(delegate: PostgresConverterDelegate()).convert(schema)) { row in
            fatalError("unexpected output")
        }
    }
}

extension PostgresRow: DatabaseOutput {
    public func contains(field: String) -> Bool {
        return self.column(field) != nil
    }

    public func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.decode(column: field, as: T.self)
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
