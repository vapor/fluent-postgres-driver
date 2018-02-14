import Foundation

internal final class PostgreSQLRowEncoder: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any]
    var data: [String: PostgreSQLData]
    init() {
        self.codingPath = []
        self.userInfo = [:]
        self.data = [:]
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = PostgreSQLRowKeyedEncodingContainer<Key>(encoder: self)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        unsupported()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        unsupported()
    }

}

private func unsupported() -> Never {
    fatalError("""
    PostgreSQL rows only support a flat, keyed structure `[String: T]`.

    Query data must be an encodable dictionary, struct, or class.

    You can also conform nested types to `PostgreSQLJSONType` or `PostgreSQLArrayType`. (Nested types must be `PostgreSQLDataCustomConvertible`.)
    """)
}

fileprivate struct PostgreSQLRowKeyedEncodingContainer<K>: KeyedEncodingContainerProtocol
    where K: CodingKey
{
    var codingPath: [CodingKey]
    let encoder: PostgreSQLRowEncoder
    init(encoder: PostgreSQLRowEncoder) {
        self.encoder = encoder
        self.codingPath = []
    }

    mutating func encodeNil(forKey key: K) throws { encoder.data[key.stringValue] = PostgreSQLData(type: .void, data: nil) }
    mutating func encode(_ value: Bool, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int16, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int32, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int64, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt8, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt16, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt32, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt64, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Double, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Float, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: String, forKey key: K) throws { encoder.data[key.stringValue] = try value.convertToPostgreSQLData() }
    mutating func superEncoder() -> Encoder { return encoder }
    mutating func superEncoder(forKey key: K) -> Encoder { return encoder }
    mutating func encodeIfPresent<T>(_ value: T?, forKey key: K) throws where T : Encodable {
        if let value = value {
            try encode(value, forKey: key)
        } else {
            if let convertibleType = T.self as? PostgreSQLDataCustomConvertible.Type {
                encoder.data[key.stringValue] = PostgreSQLData(type: convertibleType.postgreSQLDataType, data: nil)
            } else {
                try encodeNil(forKey: key)
            }
        }
    }
    mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
        guard let convertible = value as? PostgreSQLDataCustomConvertible else {
            let type = Swift.type(of: value)
            throw PostgreSQLError(
                identifier: "convertible",
                reason: "Unsupported encodable type: \(type)",
                suggestedFixes: [
                    "Conform \(type) to PostgreSQLDataCustomConvertible"
                ]
            )
        }
        encoder.data[key.stringValue] = try convertible.convertToPostgreSQLData()
    }
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return encoder.container(keyedBy: NestedKey.self)
    }

    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }
}
