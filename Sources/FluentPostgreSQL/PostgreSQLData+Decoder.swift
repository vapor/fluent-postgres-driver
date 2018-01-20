extension PostgreSQLData: SingleValueDecodingContainer {
    public var codingPath: [CodingKey] { return [] }
    public func decodeNil() -> Bool { return data == nil }
    public func decode(_ type: Int.Type) throws -> Int { return try decode() }
    public func decode(_ type: Int8.Type) throws -> Int8 { return try decode() }
    public func decode(_ type: Int16.Type) throws -> Int16 { return try decode() }
    public func decode(_ type: Int32.Type) throws -> Int32 { return try decode() }
    public func decode(_ type: Int64.Type) throws -> Int64 { return try decode() }
    public func decode(_ type: UInt.Type) throws -> UInt { return try decode() }
    public func decode(_ type: UInt8.Type) throws -> UInt8 { return try decode() }
    public func decode(_ type: UInt16.Type) throws -> UInt16 { return try decode() }
    public func decode(_ type: UInt32.Type) throws -> UInt32 { return try decode() }
    public func decode(_ type: UInt64.Type) throws -> UInt64 { return try decode() }
    public func decode(_ type: Double.Type) throws -> Double { return try decode() }
    public func decode(_ type: Float.Type) throws -> Float { return try decode() }
    public func decode(_ type: Bool.Type) throws -> Bool { return try decode() }
    public func decode(_ type: String.Type) throws -> String { return try decode() }
    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard let convertible = type as? PostgreSQLDataCustomConvertible.Type else {
            throw PostgreSQLError(
                identifier: "convertible",
                reason: "Unsupported decodable type: \(type)",
                suggestedFixes: [
                    "Conform \(type) to PostgreSQLDataCustomConvertible"
                ]
            )
        }
        return try convertible.convertFromPostgreSQLData(self) as! T
    }
}
