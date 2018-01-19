public protocol PostgreSQLModel: Model
    where Database == PostgreSQLDatabase { }

extension PostgreSQLModel {
    /// See `Model.Database`
    public typealias Database = PostgreSQLDatabase
}
