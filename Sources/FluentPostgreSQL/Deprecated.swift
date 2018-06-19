@available(*, deprecated, renamed: "PostgreSQLDataConvertible")
public typealias PostgreSQLColumnStaticRepresentable = PostgreSQLDataConvertible

/// - warning: Deprecated.
@available(*, deprecated, renamed: "PostgreSQLType")
public protocol PostgreSQLJSONType: PostgreSQLType { }

/// - warning: Deprecated.
@available(*, deprecated, renamed: "PostgreSQLType")
public protocol PostgreSQLArrayType: PostgreSQLType { }

// - warning: Deprecated.
@available(*, deprecated, message: "Use custom migration instead.")
public protocol PostgreSQLEnumType { }

// - warning: Deprecated.
@available(*, deprecated, message: "Use custom migration instead.")
public protocol PostgreSQLType { }


//extension QueryBuilder where Database == PostgreSQLDatabase {
//    /// - warning: Deprecated.
//    @available(*, deprecated, renamed: "groupBy(_:)")
//    public func group<T>(by field: KeyPath<Result, T>) -> Self {
//        return groupBy(field)
//    }
//}
