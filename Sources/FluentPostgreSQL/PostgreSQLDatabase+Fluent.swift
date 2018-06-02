/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: SQLSupporting {
    /// See `SQLDatabase`.
    public typealias QueryJoin = SQLQuery.DML.Join
    
    /// See `SQLDatabase`.
    public typealias QueryJoinMethod = SQLQuery.DML.Join.Method
    
    /// See `SQLDatabase`.
    public typealias Query = SQLQuery.DML
    
    /// See `SQLDatabase`.
    public typealias Output = [PostgreSQLColumn: PostgreSQLData]
    
    /// See `SQLDatabase`.
    public typealias QueryAction = SQLQuery.DML.Statement
    
    /// See `SQLDatabase`.
    public typealias QueryAggregate = String
    
    /// See `SQLDatabase`.
    public typealias QueryData = [SQLQuery.DML.Column: SQLQuery.DML.Value]
    
    /// See `SQLDatabase`.
    public typealias QueryField = SQLQuery.DML.Column
    
    /// See `SQLDatabase`.
    public typealias QueryFilterMethod = SQLQuery.DML.Predicate.Comparison
    
    /// See `SQLDatabase`.
    public typealias QueryFilterValue = SQLQuery.DML.Value
    
    /// See `SQLDatabase`.
    public typealias QueryFilter = SQLQuery.DML.Predicate
    
    /// See `SQLDatabase`.
    public typealias QueryFilterRelation = SQLQuery.DML.Predicate.Relation
    
    /// See `SQLDatabase`.
    public typealias QueryKey = SQLQuery.DML.Key
    
    /// See `SQLDatabase`.
    public typealias QuerySort = SQLQuery.DML.OrderBy
    
    /// See `SQLDatabase`.
    public typealias QuerySortDirection = SQLQuery.DML.OrderBy.Direction
    
    /// See `SQLDatabase`.
    public static func queryExecute(
        _ query: SQLQuery.DML,
        on conn: PostgreSQLConnection,
        into handler: @escaping ([PostgreSQLColumn: PostgreSQLData], PostgreSQLConnection) throws -> ()
    ) -> Future<Void> {
        // always cache the names first
        return conn.tableNames().flatMap { names in
            return conn.query(.init(.dml(query))) { row in
                try handler(row, conn)
            }
        }
    }
    
    /// See `SQLDatabase`.
    public static func queryDecode<D>(_ data: [PostgreSQLColumn: PostgreSQLData], entity: String, as decodable: D.Type, on conn: PostgreSQLConnection) -> Future<D>
        where D: Decodable
    {
        return conn.tableNames().map { names in
            return try PostgreSQLRowDecoder().decode(D.self, from: data, tableOID: names.tableOID(name: entity) ?? 0)
        }
    }

    struct InsertMetadata<ID>: Codable where ID: Codable {
        var lastval: ID
    }
    
    /// See `QuerySupporting.modelEvent`
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: PostgreSQLConnection) -> Future<M>
        where PostgreSQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self {
                var model = model
                model.fluentID = UUID() as? M.ID
                return conn.future(model)
            }
        case .didCreate:
            if M.ID.self == Int.self, model.fluentID == nil {
                return conn.simpleQuery("SELECT LASTVAL();", decoding: InsertMetadata<M.ID>.self).map { rows in
                    switch rows.count {
                    case 1:
                        var model = model
                        model.fluentID = rows[0].lastval
                        return model
                    default: throw PostgreSQLError(identifier: "lastval", reason: "Unexpected row count when querying LASTVAL.")
                    }
                }
            }
        default: break
        }

        return conn.future(model)
    }

    
    /// See `SQLSupporting`.
    public static func schemaColumnType(for type: Any.Type, primaryKey: Bool) -> SQLQuery.DDL.ColumnDefinition.ColumnType {
        var type = type
        
        var attributes: [String] = []
        
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
        } else {
            attributes.append("NOT NULL")
        }
        
        let isArray: Bool
        if let array = type as? AnyArray.Type {
            type = array.anyElementType
            isArray = true
        } else {
            isArray = false
        }
        
        var name: String
        
        if let representable = type as? PostgreSQLType.Type {
            name = representable.postgreSQLColumnType
            if primaryKey {
                attributes.append("PRIMARY KEY")
                switch name {
                case "INT", "SMALLINT", "BIGINT":
                    if _globalEnableIdentityColumns {
                        attributes.append("GENERATED BY DEFAULT AS IDENTITY")
                    } else {
                        name = name.replacingOccurrences(of: "INT", with: "SERIAL")
                    }
                default: break
                }
            }
        } else {
            // for any unrecognized types, assume they will be serialized to JSON.
            name = PostgreSQLDatabase.ColumnType.jsonb
        }
        
        if isArray {
            name += "[]"
        }

        return .init(name: name, parameters: [], attributes: attributes)
    }
    
    /// See `SQLSupporting`.
    public static func schemaExecute(_ ddl: SQLQuery.DDL, on connection: PostgreSQLConnection) -> Future<Void> {
        let sql = PostgreSQLSerializer().serialize(ddl: ddl)
        return connection.query(sql).transform(to: ())
    }
    
    
    /// See `SQLSupporting`.
    public static func enableReferences(on connection: PostgreSQLConnection) -> Future<Void> {
        // enabled by default
        return .done(on: connection)
    }
    
    /// See `SQLSupporting`.
    public static func disableReferences(on connection: PostgreSQLConnection) -> Future<Void> {
        return Future.map(on: connection) {
            throw PostgreSQLError(identifier: "disableReferences", reason: "PostgreSQL does not support disabling foreign key checks.")
        }
    }
    
    /// See `SQLSupporting`.
    public static func transactionExecute<T>(_ transaction: @escaping (PostgreSQLConnection) throws -> Future<T>, on connection: PostgreSQLConnection) -> Future<T> {
        return connection.simpleQuery("BEGIN TRANSACTION").flatMap { results in
            return try transaction(connection).flatMap { res in
                return connection.simpleQuery("END TRANSACTION").transform(to: res)
            }.catchFlatMap { error in
                return connection.simpleQuery("ROLLBACK").map { results in
                    throw error
                }
            }
        }
    }
}