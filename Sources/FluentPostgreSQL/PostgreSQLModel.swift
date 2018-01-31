public protocol PostgreSQLModel: Model where Self.Database == PostgreSQLDatabase { }

extension PostgreSQLModel {
    /// See `Model.Database`
    public typealias Database = PostgreSQLDatabase
}
