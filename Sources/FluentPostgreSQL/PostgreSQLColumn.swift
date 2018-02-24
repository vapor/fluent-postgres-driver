/// A PostgreSQL column type and size.
public struct PostgreSQLColumn {
    /// The columns data type.
    public let type: PostgreSQLDataType

    /// The columns size. Negative values mean varying size.
    public let size: Int16

    /// Creates a new `PostgreSQLColumn`.
    public init(type: PostgreSQLDataType, size: Int16? = nil) {
        self.type = type
        self.size = size ?? -1
    }
}

/// MARK: Representable

/// Capable of being represented statically by a `PostgreSQLColumn`
public protocol PostgreSQLColumnStaticRepresentable {
    /// The `PostgreSQLColumn` type that best represents this type.
    static var postgreSQLColumn: PostgreSQLColumn { get }
}

