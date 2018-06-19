public protocol _PostgreSQLModel: Model, PostgreSQLTable where Self.Database == PostgreSQLDatabase { }

extension _PostgreSQLModel {
    /// See `SQLTable`.
    public static var sqlTableIdentifierString: String {
        return entity
    }
}

public protocol PostgreSQLModel: _PostgreSQLModel where Self.ID == Int {
    /// This model's unique identifier.
    var id: Int? { get set }
}

extension PostgreSQLModel {
    /// See `Model`.
    public static var idKey: IDKey { return \.id }
}

public protocol PostgreSQLPivot: Pivot, PostgreSQLModel { }

public protocol PostgreSQLMigration: Migration where Self.Database == PostgreSQLDatabase { }
