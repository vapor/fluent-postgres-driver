public protocol PostgreSQLEnum: PostgreSQLValueRepresentable, CaseIterable, Codable, ReflectionDecodable, PostgreSQLStaticColumnTypeRepresentable, RawRepresentable where Self.RawValue: LosslessStringConvertible {
    static var postgreSQLEnumTypeName: String { get }
}

extension PostgreSQLEnum {
    public static var postgreSQLEnumTypeName: String {
        return "\(self)".uppercased()
    }
    
    public static var postgreSQLColumnType: PostgreSQLColumnType {
        return .custom(postgreSQLEnumTypeName)
    }
    
    public var postgreSQLValue: PostgreSQLQuery.Value {
        return .expression(.stringLiteral(rawValue.description))
    }
}

extension PostgreSQLEnum where Self: PostgreSQLMigration {
    public static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(enum: self, on: conn)
    }
    
    public static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.drop(enum: self, on: conn)
    }
}

extension PostgreSQLDatabase {
    public static func create<E>(enum: E.Type, on conn: PostgreSQLConnection) -> Future<Void> where E: PostgreSQLEnum {
        let cases = E.allCases.map { "'" + $0.rawValue.description + "'" }.joined(separator: ", ")
        return conn.simpleQuery(.raw(
            query: "CREATE TYPE \(E.postgreSQLEnumTypeName) AS ENUM (\(cases))",
            binds: []
        )).transform(to: ())
    }
    
    public static func alter<E>(enum: E.Type, add value: E, on conn: PostgreSQLConnection) -> Future<Void> where E: PostgreSQLEnum {
        return conn.simpleQuery(.raw(
            query: "ALTER TYPE \(E.postgreSQLEnumTypeName) ADD VALUE '\(value.rawValue.description)'",
            binds: []
        )).transform(to: ())
    }
    
    public static func drop<E>(enum: E.Type, on conn: PostgreSQLConnection) -> Future<Void> where E: PostgreSQLEnum {
        return conn.simpleQuery(.raw(
            query: "DROP TYPE \(E.postgreSQLEnumTypeName)",
            binds: []
        )).transform(to: ())
    }
}
