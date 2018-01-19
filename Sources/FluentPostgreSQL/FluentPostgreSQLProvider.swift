import Service

/// Adds Fluent PostgreSQL's services to your project.
public final class FluentPostgreSQLProvider: Provider {
    /// See `Provider.repositoryName`
    public static let repositoryName = "fluent-postgresql"

    /// Creates a new `FluentPostgreSQLProvider`
    public init() {}

    /// See `Provider.register(_:)`
    public func register(_ services: inout Services) throws {
        try services.register(FluentProvider())
        try services.register(PostgreSQLProvider())
    }

    /// See `Provider.boot(_:)`
    public func boot(_ worker: Container) throws { }
}
