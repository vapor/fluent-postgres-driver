import Async
import CodableKit
import FluentSQL
import Foundation

/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: QuerySupporting, CustomSQLSupporting {
    /// See `QuerySupporting.execute`
    public static func execute(
        query: DatabaseQuery<PostgreSQLDatabase>,
        into handler: @escaping ([QueryField: PostgreSQLData], PostgreSQLConnection) throws -> (),
        on connection: PostgreSQLConnection
    ) -> EventLoopFuture<Void> {
        /// wait for the table name cache before continuing
        return PostgreSQLTableNameCache.get(for: connection).flatMap(to: Void.self) { tableNameCache in
            // Convert Fluent `DatabaseQuery` to generic FluentSQL `DataQuery`
            var (sqlQuery, bindValues) = query.makeDataQuery()

            // If the query has an Encodable model attached serialize it.
            // Dictionary keys should be added to the DataQuery as columns.
            // Dictionary values should be added to the parameterized array.
            var modelData: [PostgreSQLData] = []
            modelData.reserveCapacity(query.data.count)
            for (field, data) in query.data {
                if case .create = query.action, data.isNull && field.name == "id" { continue } // bad hack
                sqlQuery.columns.append(DataColumn(table: field.entity, name: field.name))
                modelData.append(data)
            }

            /// Apply custom sql transformations
            for customSQL in query.customSQL {
                customSQL.closure(&sqlQuery)
            }

            // Create a PostgreSQL-flavored SQL serializer to create a SQL string
            let sqlSerializer = PostgreSQLSQLSerializer()
            let sqlString = sqlSerializer.serialize(data: sqlQuery)

            /// Convert params
            let parameters: [PostgreSQLData] = modelData + bindValues

            /// Log supporting
            if let logger = connection.logger {
                logger.log(query: sqlString, parameters: parameters)
            }

            // Run the query
            return try connection.query(sqlString, parameters) { row in
                var res: [QueryField: PostgreSQLData] = [:]
                for (col, data) in row {
                    let field = QueryField(entity: tableNameCache.storage[col.tableOID], name: col.name)
                    res[field] = data
                }
                try handler(res, connection)
            }
        }
    }

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

    /// See `QuerySupporting.QueryFilter`
    public typealias QueryFilter = DataPredicateComparison
}

extension PostgreSQLData: FluentData {}
