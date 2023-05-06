#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import FluentKit
@_documentation(visibility: internal) @_exported import PostgresKit

#else

@_exported import FluentKit
@_exported import PostgresKit

#endif

extension DatabaseID {
    public static var psql: DatabaseID {
        return .init(string: "psql")
    }
}
