extension PostgreSQLData: Encodable {
    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}

public struct PostgreSQLField: Hashable {
    public var hashValue: Int {
        if let table = table {
            return table.hashValue &+ name.hashValue
        } else {
            return name.hashValue
        }
    }
    
    var table: String?
    var name: String
}

/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: QuerySupporting, KeyedCacheSupporting {
    /// See `SQLDatabase`.
    public static func queryExecute(
        _ dml: DataManipulationQuery,
        on conn: PostgreSQLConnection,
        into handler: @escaping ([PostgreSQLField: PostgreSQLData], PostgreSQLConnection) throws -> ()
    ) -> Future<Void> {
        // wait for the table name cache before continuing
        return PostgreSQLTableNameCache.get(for: conn).flatMap { tableNameCache in
            var binds = Binds()
            let sql = PostgreSQLSQLSerializer().serialize(query: dml, binds: &binds)
            let params = try binds.values.map { encodable -> PostgreSQLData in
                guard let convertible = encodable as? PostgreSQLDataConvertible else {
                    throw PostgreSQLError(identifier: "dataConvertible", reason: "Could not convert \(type(of: encodable)) to PostgreSQL data.", source: .capture())
                }
                return try convertible.convertToPostgreSQLData()
            }
            return conn.query(sql, params) { row in
                var res: [PostgreSQLField: PostgreSQLData] = [:]
                for (col, data) in row {
                    let field = PostgreSQLField(table: tableNameCache.storage[col.tableOID], name: col.name)
                    res[field] = data
                }
                try handler(res, conn)
            }
        }
    }
    
    /// See `SQLDatabase`.
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [DataManipulationColumn] where E: Encodable {
        let encoder = PostgreSQLRowEncoder()
        try encodable.encode(to: encoder)
        return encoder.data.map { (row) -> DataManipulationColumn in
            if row.value.isNull {
                return .init(column: .init(table: nil, name: row.key), value: .null)
            } else {
                return .init(column: .init(table: nil, name: row.key), value: .binds([row.value]))
            }
        }
    }
    
    /// See `SQLDatabase`.
    public static func queryDecode<D>(_ data: [PostgreSQLField: PostgreSQLData], entity: String, as decodable: D.Type) throws -> D
        where D: Decodable
    {
        var row: [String: PostgreSQLData] = [:]
        for (field, val) in data {
            if field.table == nil || field.table == entity {
                row[field.name] = val
            }
        }
        return try D.init(from: PostgreSQLRowDecoder(row: row))
    }

//    /// See `QuerySupporting.execute`
//    public static func execute(
//        query: DatabaseQuery<PostgreSQLDatabase>,
//        into handler: @escaping ([QueryField: PostgreSQLData], PostgreSQLConnection) throws -> (),
//        on connection: PostgreSQLConnection
//    ) -> EventLoopFuture<Void> {
//        /// wait for the table name cache before continuing
//        return PostgreSQLTableNameCache.get(for: connection).flatMap(to: Void.self) { tableNameCache in
//            // Convert Fluent `DatabaseQuery` to generic FluentSQL `DataQuery`
//            var (sqlQuery, bindValues) = query.makeDataQuery()
//
//            /// Convert params
//            let parameters: [PostgreSQLData]
//
//            switch sqlQuery {
//            case .manipulation(var m):
//                // If the query has an Encodable model attached serialize it.
//                // Dictionary keys should be added to the DataQuery as columns.
//                // Dictionary values should be added to the parameterized array.
//                var modelData: [PostgreSQLData] = []
//                modelData.reserveCapacity(query.data.count)
//                m.columns = query.data.compactMap { (field, data) in
//                    // if case .create = query.action, data.isNull && field.name == "id" { return nil } // bad hack
//                    modelData.append(data)
//                    let col = DataColumn(table: field.entity, name: field.name)
//                    return .init(column: col, value: .placeholder)
//                }
//                parameters = modelData + bindValues
//                sqlQuery = .manipulation(m)
//            case .query: parameters = bindValues
//            case .definition: parameters = []
//            }
//
//            /// Apply custom sql transformations
//            for customSQL in query.customSQL {
//                customSQL.closure(&sqlQuery)
//            }
//
//            // Create a PostgreSQL-flavored SQL serializer to create a SQL string
//            let sqlSerializer = PostgreSQLSQLSerializer()
//            let sqlString = sqlSerializer.serialize(sqlQuery)
//
//            // Run the query
//            return connection.query(sqlString, parameters) { row in
//                var res: [QueryField: PostgreSQLData] = [:]
//                for (col, data) in row {
//                    let field = QueryField(entity: tableNameCache.storage[col.tableOID], name: col.name)
//                    res[field] = data
//                }
//                try handler(res, connection)
//            }
//        }
//    }

    /// See `QuerySupporting.modelEvent`
    public static func modelEvent<M>(event: ModelEvent, model: M, on connection: PostgreSQLConnection) -> Future<M>
        where PostgreSQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self {
                var model = model
                model.fluentID = UUID() as? M.ID
                return Future.map(on: connection) { model }
            }
        case .didCreate:
            if M.ID.self == Int.self, model.fluentID == nil {
                return connection.simpleQuery("SELECT LASTVAL();").map(to: M.self) { row in
                    var model = model
                    try model.fluentID = row[0].firstValue(forColumn: "lastval")?.decode(Int.self) as? M.ID
                    return model
                }
            }
        default: break
        }

        return Future.map(on: connection) { model }
    }

    /// See `QuerySupporting.QueryDataConvertible`
    public typealias QueryDataConvertible = PostgreSQLDataConvertible

    /// See `QuerySupporting.queryDataParse(_:from:)`
    public static func queryDataParse<T>(_ type: T.Type, from data: PostgreSQLData) throws -> T? {
        if data.isNull {
            return nil
        }
        guard let convertibleType = T.self as? PostgreSQLDataConvertible.Type else {
            throw PostgreSQLError(identifier: "queryDataParse", reason: "Cannot parse \(T.self) from PostgreSQLData", source: .capture())
        }
        let t: T = try convertibleType.convertFromPostgreSQLData(data) as! T
        return t
    }

    /// See `QuerySupporting.queryDataSerialize(data:)`
    public static func queryDataSerialize<T>(data: T?) throws -> PostgreSQLData {
        if let data = data {
            guard let convertible = data as? PostgreSQLDataConvertible else {
                throw PostgreSQLError(identifier: "queryDataSerialize", reason: "Cannot serialize \(T.self) to PostgreSQLData", source: .capture())
            }
            return try convertible.convertToPostgreSQLData()
        } else {
            guard let convertibleType = T.self as? PostgreSQLDataConvertible.Type else {
                throw PostgreSQLError(identifier: "queryDataParse", reason: "Cannot parse \(T.self) from PostgreSQLData", source: .capture())
            }
            return PostgreSQLData(type: convertibleType.postgreSQLDataType, format: .binary, data: nil)
        }
    }
}
