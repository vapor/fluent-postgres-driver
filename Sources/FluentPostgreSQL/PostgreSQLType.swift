/// A type that is compatible with PostgreSQL schema and data.
public protocol PostgreSQLType: PostgreSQLDataConvertible {
    /// Appropriate PostgreSQL column type for storing this type.
    static var postgreSQLColumnType: String { get }
}

/// An enum type compatible with PostgreSQL.
public protocol PostgreSQLEnumType: PostgreSQLType, ReflectionDecodable, Codable, RawRepresentable where Self.RawValue: PostgreSQLDataConvertible { }

extension RawRepresentable where RawValue: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String {
        return RawValue.postgreSQLColumnType
    }
}

/// MARK: Default Implementations

extension Data: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.bytea }
}

extension UUID: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.uuid }
}

extension Date: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.timestamp }
}

extension Int: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.int }
}

extension Int8: PostgreSQLType  {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.char }
}

extension Int16: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.smallint }
}

extension Int32: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.int }
}

extension Int64: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.bigint }
}

extension UInt: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.bigint }
}

extension UInt8: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.char }
}

extension UInt16: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.smallint }
}

extension UInt32: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.int }
}

extension UInt64: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.bigint }
}

extension Float: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.real }
}

extension Double: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.doublePrecision }
}

extension String: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.text }
}

extension Bool: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.bool }
}

extension PostgreSQLPoint: PostgreSQLType {
    /// See `PostgreSQLType`.
    public static var postgreSQLColumnType: String { return PostgreSQLDatabase.ColumnType.point }
}
