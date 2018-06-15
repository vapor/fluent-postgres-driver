import Foundation

public protocol PostgreSQLStringModel: Model where Self.Database == PostgreSQLDatabase, Self.ID == String {
    /// This model's unique identifier.
    var id: String? { get set }
}

extension PostgreSQLStringModel {
    /// See `Model.idKey`
    public static var idKey: IDKey { return \.id }
}

public protocol PostgreSQLStringPivot: Pivot, PostgreSQLStringModel { }
