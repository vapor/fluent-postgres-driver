public protocol PostgreSQLStringModel: _PostgreSQLModel where Self.ID == String {
    /// This model's unique identifier.
    var id: String? { get set }
}

extension PostgreSQLStringModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

public protocol PostgreSQLStringPivot: Pivot, PostgreSQLStringModel { }
