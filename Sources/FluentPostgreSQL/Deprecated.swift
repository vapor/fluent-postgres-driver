@available(*, deprecated, renamed: "PostgreSQLDataConvertible")
public typealias PostgreSQLColumnStaticRepresentable = PostgreSQLDataConvertible

/// - warning: Deprecated.
@available(*, deprecated, renamed: "PostgreSQLType")
public protocol PostgreSQLJSONType: PostgreSQLType { }

/// - warning: Deprecated.
@available(*, deprecated, renamed: "PostgreSQLType")
public protocol PostgreSQLArrayType: PostgreSQLType { }


/// - warning: Deprecated.
@available(*, deprecated, renamed: "SQLSupporting")
public typealias SchemaSupporting = SQLSupporting

// - warning: Deprecated.
@available(*, deprecated, message: "Use custom migration instead.")
public protocol PostgreSQLEnumType { }

// - warning: Deprecated.
@available(*, deprecated, message: "Use custom migration instead.")
public protocol PostgreSQLType { }

