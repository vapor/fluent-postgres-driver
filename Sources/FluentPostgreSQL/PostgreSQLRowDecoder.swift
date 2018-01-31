internal final class PostgreSQLRowDecoder: Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let data: [String: PostgreSQLData]
    init(row: [String: PostgreSQLData]) {
        self.data = row
        self.codingPath = []
        self.userInfo = [:]
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = PostgreSQLRowKeyedDecodingContainer<Key>(decoder: self)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw unsupported()
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw unsupported()
    }

    func require(key: CodingKey) throws -> PostgreSQLData {
        guard let data = self.data[key.stringValue] else {
            throw PostgreSQLError(identifier: "decode", reason: "No value found at key: \(key)")
        }
        return data
    }

}

private func unsupported() -> PostgreSQLError {
    return PostgreSQLError(
        identifier: "rowDecode",
        reason: "PostgreSQL rows only support a flat, keyed structure `[String: T]`",
        suggestedFixes: [
            "You can conform nested types to `PostgreSQLJSONType` or `PostgreSQLArrayType`. (Nested types must be `PostgreSQLDataCustomConvertible`.)"
        ]
    )
}


fileprivate struct PostgreSQLRowKeyedDecodingContainer<K>: KeyedDecodingContainerProtocol
    where K: CodingKey
{
    var allKeys: [K]
    typealias Key = K
    var codingPath: [CodingKey]
    let decoder: PostgreSQLRowDecoder
    init(decoder: PostgreSQLRowDecoder) {
        self.decoder = decoder
        codingPath = []
        allKeys = self.decoder.data.keys.compactMap { K(stringValue: $0) }
    }
    func contains(_ key: K) -> Bool { return decoder.data.keys.contains(key.stringValue) }
    func decodeNil(forKey key: K) -> Bool { return decoder.data[key.stringValue]?.data == nil }
    func decode(_ type: Int.Type, forKey key: K) throws -> Int { return try decoder.require(key: key).decode(Int.self) }
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { return try decoder.require(key: key).decode(Int8.self) }
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { return try decoder.require(key: key).decode(Int16.self) }
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { return try decoder.require(key: key).decode(Int32.self) }
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { return try decoder.require(key: key).decode(Int64.self) }
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { return try decoder.require(key: key).decode(UInt.self) }
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { return try decoder.require(key: key).decode(UInt8.self) }
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { return try decoder.require(key: key).decode(UInt16.self) }
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { return try decoder.require(key: key).decode(UInt32.self) }
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { return try decoder.require(key: key).decode(UInt64.self) }
    func decode(_ type: Double.Type, forKey key: K) throws -> Double { return try decoder.require(key: key).decode(Double.self) }
    func decode(_ type: Float.Type, forKey key: K) throws -> Float { return try decoder.require(key: key).decode(Float.self) }
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool { return try decoder.require(key: key).decode(Bool.self) }
    func decode(_ type: String.Type, forKey key: K) throws -> String { return try decoder.require(key: key).decode(String.self) }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        guard let convertible = type as? PostgreSQLDataCustomConvertible.Type else {
            throw PostgreSQLError(
                identifier: "convertible",
                reason: "Unsupported decodable type: \(type)",
                suggestedFixes: [
                    "Conform \(type) to PostgreSQLDataCustomConvertible"
                ]
            )
        }
        return try convertible.convertFromPostgreSQLData(decoder.require(key: key)) as! T
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try decoder.container(keyedBy: NestedKey.self)
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return try decoder.unkeyedContainer()
    }

    func superDecoder() throws -> Decoder { return decoder }
    func superDecoder(forKey key: K) throws -> Decoder { return decoder }

}
