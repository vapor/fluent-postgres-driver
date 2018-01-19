public protocol PostgreSQLPivot: Pivot
where Database == PostgreSQLDatabase { }

extension PostgreSQLPivot {
    /// See `Model.Database`
    public typealias Database = PostgreSQLDatabase
}

