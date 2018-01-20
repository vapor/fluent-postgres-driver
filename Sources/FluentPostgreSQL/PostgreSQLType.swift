/// A type that is compatible with PostgreSQL schema and data.
public protocol PostgreSQLType: PostgreSQLColumnStaticRepresentable, PostgreSQLDataCustomConvertible { }

/// A type that is supports being represented as JSONB in a PostgreSQL database.
public protocol PostgreSQLJSONType: PostgreSQLType, PostgreSQLJSONCustomConvertible { }

extension PostgreSQLJSONType {
    /// The `PostgreSQLColumn` type that best represents this type.
    public static var postgreSQLColumn: PostgreSQLColumn { return .init(type: .jsonb) }
}
