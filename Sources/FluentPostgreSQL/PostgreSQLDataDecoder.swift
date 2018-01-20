internal struct PostgreSQLDataDecoder: SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let data: PostgreSQLData
    init(data: PostgreSQLData) {
        self.data = data
        self.userInfo = [:]
        self.codingPath = []
    }

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
}
