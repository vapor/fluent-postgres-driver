import Foundation

public protocol PostgreSQLUUIDModel: Model where Self.Database == PostgreSQLDatabase, Self.ID == UUID {
    /// This model's unique identifier.
    var id: UUID? { get set }
}

extension PostgreSQLUUIDModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

public protocol PostgreSQLUUIDPivot: Pivot, PostgreSQLUUIDModel { }
