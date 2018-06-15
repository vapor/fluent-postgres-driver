public protocol PostgreSQLModel: Model where Self.Database == PostgreSQLDatabase, Self.ID == Int {
    /// This model's unique identifier.
    var id: Int? { get set }
}

extension PostgreSQLModel {
    /// See `Model`.
    public static var idKey: IDKey { return \.id }
}

public protocol PostgreSQLStringModel: Model where Self.Database == PostgreSQLDatabase, Self.ID == String {
    /// This model's unique identifier.
    var id: String? { get set }
}

extension PostgreSQLStringModel {
    /// See `Model`.
    public static var idKey: IDKey { return \.id }
}


public protocol PostgreSQLPivot: Pivot, PostgreSQLModel { }

public protocol PostgreSQLMigration: Migration where Self.Database == PostgreSQLDatabase { }
