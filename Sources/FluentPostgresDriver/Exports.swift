@_exported import FluentKit
@_exported import PostgresKit

extension DatabaseID {
    public static var psql: DatabaseID {
        return .init(string: "psql")
    }
}
