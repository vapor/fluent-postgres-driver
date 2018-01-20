import Async
import CodableKit
import FluentSQL
import Foundation

/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: QuerySupporting {
    /// See `QuerySupporting.execute`
    public static func execute<I, D>(query: DatabaseQuery<PostgreSQLDatabase>, into stream: I, on connection: PostgreSQLConnection)
        where I: Async.InputStream, D: Decodable, D == I.Input
    {
        let future = Future<Void>.flatMap {
            // Convert Fluent `DatabaseQuery` to generic FluentSQL `DataQuery`
            var (sqlQuery, bindValues) = query.makeDataQuery()

            // If the query has an Encodable model attached serialize it.
            // Dictionary keys should be added to the DataQuery as columns.
            // Dictionary values should be added to the parameterized array.
            let modelData: [PostgreSQLData]
            if let model = query.data {
                let encoded = try CodableDataEncoder().encode(model)
                switch encoded {
                case .dictionary(let dict):
                    sqlQuery.columns += dict.keys.map { key in
                        return DataColumn(table: query.entity, name: key)
                    }
                    modelData = try dict.values.map { codableData -> PostgreSQLData in
                        switch codableData {
                        case .bool(let value): return try value.convertToPostgreSQLData()
                        case .int(let value): return try value.convertToPostgreSQLData()
                        case .int8(let value): return try value.convertToPostgreSQLData()
                        case .int16(let value): return try value.convertToPostgreSQLData()
                        case .int32(let value): return try value.convertToPostgreSQLData()
                        case .int64(let value): return try value.convertToPostgreSQLData()
                        case .uint(let value): return try value.convertToPostgreSQLData()
                        case .uint8(let value): return try value.convertToPostgreSQLData()
                        case .uint16(let value): return try value.convertToPostgreSQLData()
                        case .uint32(let value): return try value.convertToPostgreSQLData()
                        case .uint64(let value): return try value.convertToPostgreSQLData()
                        case .float(let value): return try value.convertToPostgreSQLData()
                        case .double(let value): return try value.convertToPostgreSQLData()
                        case .string(let value): return try value.convertToPostgreSQLData()
                        case .null: return PostgreSQLData(type: .void)
                        case .encodable(let encodable):
                            guard let convertible = encodable as? PostgreSQLDataCustomConvertible else {
                                let type = Swift.type(of: encodable)
                                throw PostgreSQLError(
                                    identifier: "convertible",
                                    reason: "Unsupported encodable type: \(type)",
                                    suggestedFixes: [
                                        "Conform \(type) to PostgreSQLDataCustomConvertible"
                                    ]
                                )
                            }
                            return try convertible.convertToPostgreSQLData()
                        case .array, .dictionary, .decoder:
                            throw PostgreSQLError(identifier: "codable", reason: "Unsupported codable type: \(codableData)")
                        }
                    }
                default:
                    throw PostgreSQLError(
                        identifier: "queryData",
                        reason: "Unsupported PostgreSQLData (dictionary required) created by query data: \(model)"
                    )
                }
            } else {
                modelData = []
            }

            // Create a PostgreSQL-flavored SQL serializer to create a SQL string
            let sqlSerializer = PostgreSQLSQLSerializer()
            let sqlString = sqlSerializer.serialize(data: sqlQuery)

            // Combine the query data with bind values from filters.
            // All bind values must come _after_ the columns section of the query.
            let parameters = try modelData + bindValues.map { bind in
                let encodable = bind.encodable
                guard let convertible = encodable as? PostgreSQLDataCustomConvertible else {
                    let type = Swift.type(of: encodable)
                    throw PostgreSQLError(
                        identifier: "convertible",
                        reason: "Unsupported encodable type: \(type)",
                        suggestedFixes: [
                            "Conform \(type) to PostgreSQLDataCustomConvertible"
                        ]
                    )
                }
                return try convertible.convertToPostgreSQLData()
            }

            // Create a push stream to accept the psql output
            // FIXME: connect streams directly instead?
            let pushStream = PushStream<D>()
            pushStream.output(to: stream)

            // Run the query
            return try connection.query(sqlString, parameters) { row in
                let codableDict = row.mapValues { psqlData -> CodableData in
                    return .decoder(PostgreSQLDataDecoder(data: psqlData))
                }
                do {
                    let decoded = try CodableDataDecoder().decode(D.self, from: .dictionary(codableDict))
                    pushStream.push(decoded)
                } catch {
                    pushStream.error(error)
                }
            }
        }

        /// Convert Future completion / error to stream
        future.do {
            // Query is complete
            stream.close()
        }.catch { error in
            // Query failed
            stream.error(error)
            stream.close()
        }
    }

    /// See `QuerySupporting.modelEvent`
    public static func modelEvent<M>(event: ModelEvent, model: M, on connection: PostgreSQLConnection) -> Future<Void>
        where PostgreSQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self {
                model.fluentID = UUID() as? M.ID
            }
        case .didCreate:
            if M.ID.self == Int.self {
                return connection.simpleQuery("SELECT LASTVAL();").map(to: Void.self) { row in
                    try! model.fluentID = row[0]["lastval"]?.decode(Int.self) as? M.ID
                }
            }
        default: break
        }
        
        return .done
    }
}


internal struct PostgreSQLDataDecoder: Decoder, SingleValueDecodingContainer {

    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let data: PostgreSQLData
    init(data: PostgreSQLData) {
        self.data = data
        self.userInfo = [:]
        self.codingPath = []
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer { return self }
    func decodeNil() -> Bool { return data.data == nil }
    func decode(_ type: Int.Type) throws -> Int { return try data.decode(Int.self) }
    func decode(_ type: Int8.Type) throws -> Int8 { return try data.decode(Int8.self) }
    func decode(_ type: Int16.Type) throws -> Int16 { return try data.decode(Int16.self) }
    func decode(_ type: Int32.Type) throws -> Int32 { return try data.decode(Int32.self) }
    func decode(_ type: Int64.Type) throws -> Int64 { return try data.decode(Int64.self) }
    func decode(_ type: UInt.Type) throws -> UInt { return try data.decode(UInt.self) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return try data.decode(UInt8.self) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return try data.decode(UInt16.self) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return try data.decode(UInt32.self) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return try data.decode(UInt64.self) }
    func decode(_ type: Double.Type) throws -> Double { return try data.decode(Double.self) }
    func decode(_ type: Float.Type) throws -> Float { return try data.decode(Float.self) }
    func decode(_ type: Bool.Type) throws -> Bool { return try data.decode(Bool.self) }
    func decode(_ type: String.Type) throws -> String { return try data.decode(String.self) }
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard let convertible = type as? PostgreSQLDataCustomConvertible.Type else {
            throw PostgreSQLError(
                identifier: "convertible",
                reason: "Unsupported decodable type: \(type)",
                suggestedFixes: [
                    "Conform \(type) to PostgreSQLDataCustomConvertible"
                ]
            )
        }
        return try convertible.convertFromPostgreSQLData(data) as! T
    }

    // unsupported
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        throw PostgreSQLError(
            identifier: "decoding",
            reason: "Keyed decoding container not supported",
            suggestedFixes: ["Use a nested struct isntead"]
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw PostgreSQLError(
            identifier: "decoding",
            reason: "Unkeyed decoding container not supported",
            suggestedFixes: ["Use a nested struct isntead"]
        )
    }
}
