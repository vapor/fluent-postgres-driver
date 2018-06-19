public protocol PostgreSQLUUIDModel: _PostgreSQLModel where Self.ID == UUID {
    /// This model's unique identifier.
    var id: UUID? { get set }
}

extension PostgreSQLUUIDModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

public protocol PostgreSQLUUIDPivot: Pivot, PostgreSQLUUIDModel { }
