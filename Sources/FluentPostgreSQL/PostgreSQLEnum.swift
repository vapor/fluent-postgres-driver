public protocol PostgreSQLEnum: PostgreSQLExpressionRepresentable, CaseIterable, Codable, ReflectionDecodable, PostgreSQLDataTypeStaticRepresentable, RawRepresentable where Self.RawValue: LosslessStringConvertible {
    static var postgreSQLEnumTypeName: String { get }
}

public protocol PostgreSQLRawEnum: RawRepresentable, Codable, CaseIterable, ReflectionDecodable, PostgreSQLDataTypeStaticRepresentable { }

extension PostgreSQLRawEnum where Self.RawValue: PostgreSQLDataTypeStaticRepresentable {
    /// See `PostgreSQLDataTypeStaticRepresentable`.
    public static var postgreSQLDataType: PostgreSQLDataType {
        return RawValue.postgreSQLDataType
    }
}

extension PostgreSQLEnum {
    /// See `PostgreSQLEnum`.
    public static var postgreSQLEnumTypeName: String {
        return "\(self)".uppercased()
    }
    
    /// See `PostgreSQLDataTypeStaticRepresentable`.
    public static var postgreSQLDataType: PostgreSQLDataType {
        return .custom(postgreSQLEnumTypeName)
    }
    
    /// See `PostgreSQLExpressionRepresentable`.
    public var postgreSQLExpression: PostgreSQLExpression {
        return .literal(.string(rawValue.description))
    }
}

extension PostgreSQLEnum where Self: PostgreSQLMigration {
    /// See `PostgreSQLMigration`.
    public static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(enum: self, on: conn)
    }
    
    /// See `PostgreSQLMigration`.
    public static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.drop(enum: self, on: conn)
    }
}

extension PostgreSQLDatabase {
    public static func create<E>(enum: E.Type, on conn: PostgreSQLConnection) -> Future<Void> where E: PostgreSQLEnum {
        let cases = E.allCases.map { "'" + $0.rawValue.description + "'" }.joined(separator: ", ")
        return conn.simpleQuery("CREATE TYPE \(E.postgreSQLEnumTypeName) AS ENUM (\(cases))")
    }
    
    public static func alter<E>(enum: E.Type, add value: E, on conn: PostgreSQLConnection) -> Future<Void> where E: PostgreSQLEnum {
        return conn.simpleQuery("ALTER TYPE \(E.postgreSQLEnumTypeName) ADD VALUE '\(value.rawValue.description)'")
    }
    
    public static func drop<E>(enum: E.Type, on conn: PostgreSQLConnection) -> Future<Void> where E: PostgreSQLEnum {
        return conn.simpleQuery("DROP TYPE \(E.postgreSQLEnumTypeName)")
    }
}
