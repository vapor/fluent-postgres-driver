internal struct PostgreSQLDataEncoder: SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    var data: PostgreSQLData?
    init() {
        self.codingPath = []
    }
    mutating func encodeNil() throws { data = PostgreSQLData(type: .void) }
    mutating func encode(_ value: Bool) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int16) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int32) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Int64) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt8) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt16) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt32) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: UInt64) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Double) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: Float) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode(_ value: String) throws { data = try value.convertToPostgreSQLData() }
    mutating func encode<T>(_ value: T) throws where T : Encodable {
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
        data = try convertible.convertToPostgreSQLData()
    }
}
