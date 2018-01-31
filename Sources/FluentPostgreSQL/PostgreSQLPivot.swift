public protocol PostgreSQLPivot: Pivot where Self.Database == PostgreSQLDatabase { }

extension PostgreSQLPivot {
    /// See `Model.Database`
    public typealias Database = PostgreSQLDatabase
}

