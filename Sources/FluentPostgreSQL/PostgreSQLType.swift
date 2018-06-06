public typealias PostgreSQLColumnType = PostgreSQLQuery.DataType

public protocol PostgreSQLStaticColumnTypeRepresentable {
    /// Appropriate PostgreSQL column type for storing this type.
    static var postgreSQLColumnType: PostgreSQLColumnType { get }
}

/// MARK: Default Implementations

extension Data: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .bytea }
}

extension UUID: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .uuid }
}

extension Date: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .timestamp(nil) }
}

extension Int: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .bigint }
}

extension Int8: PostgreSQLStaticColumnTypeRepresentable  {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .char(nil) }
}

extension Int16: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .smallint }
}

extension Int32: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .int }
}

extension Int64: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .bigint }
}

extension UInt: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .bigint }
}

extension UInt8: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .char(nil) }
}

extension UInt16: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .smallint }
}

extension UInt32: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .int }
}

extension UInt64: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .bigint }
}

extension Float: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .real }
}

extension Double: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .doublePrecision }
}

extension String: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .text }
}

extension Bool: PostgreSQLStaticColumnTypeRepresentable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .bool }
}

extension PostgreSQLPoint: PostgreSQLStaticColumnTypeRepresentable, ReflectionDecodable {
    /// See `PostgreSQLStaticColumnTypeRepresentable`.
    public static var postgreSQLColumnType: PostgreSQLColumnType { return .point }
    
    /// See `ReflectionDecodable`.
    public static func reflectDecoded() throws -> (PostgreSQLPoint, PostgreSQLPoint) {
        return (.init(x: 0, y: 0), .init(x: 1, y: 1))
    }
}
