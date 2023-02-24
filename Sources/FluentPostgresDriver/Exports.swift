#if !BUILDING_DOCC

@_exported import FluentKit
@_exported import PostgresKit

#endif

extension DatabaseID {
    public static var psql: DatabaseID {
        return .init(string: "psql")
    }
}