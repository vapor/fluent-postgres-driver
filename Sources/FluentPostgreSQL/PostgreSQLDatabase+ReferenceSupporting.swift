import Async

extension PostgreSQLDatabase: ReferenceSupporting {
    /// See `ReferenceSupporting.enableReferences(on:)`
    public static func enableReferences(on connection: PostgreSQLConnection) -> Future<Void> {
        // enabled by default
        return .done
    }

    /// See `ReferenceSupporting.disableReferences(on:)`
    public static func disableReferences(on connection: PostgreSQLConnection) -> Future<Void> {
        return Future(
            error: PostgreSQLError(identifier: "disableReferences", reason: "PostgreSQL does not support disabling foreign key checks.")
        )
    }
}
