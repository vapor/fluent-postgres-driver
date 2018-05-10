import Async

/// Caches table OID to string name associations.
final class PostgreSQLTableNameCache {
    /// The internal cache.
    var storage: [Int32: String]

    /// Static shared cache, stored by connections.
    private static var _shared: ThreadSpecificVariable<PostgreSQLTableNameCaches> = .init()

    /// Getter for `_shared` that will initialize if it has not already been initialized.
    private static var shared: PostgreSQLTableNameCaches {
        get {
            if let existing = _shared.currentValue {
                return existing
            } else {
                let new = PostgreSQLTableNameCaches()
                _shared.currentValue = new
                return new
            }
        }
    }

    /// Creates a new cache.
    private init(_ cache: [Int32: String]) {
        self.storage = cache
    }

    /// Invalidates the cache for the supplied connection.
    static func invalidate(for connection: PostgreSQLConnection) {
        shared.storage[ObjectIdentifier(connection)] = nil
    }

    /// Generates a cache for the supplied connection.
    static func get(for connection: PostgreSQLConnection) -> Future<PostgreSQLTableNameCache> {
        if let existing = shared.storage[ObjectIdentifier(connection)] {
            return Future.map(on: connection) { existing }
        } else {
            return connection.simpleQuery("select oid, relname from pg_class").map(to: PostgreSQLTableNameCache.self) { rows in
                var cache: [Int32: String] = [:]

                for row in rows {
                    let oid = try row.firstValue(forColumn: "oid")!.decode(Int32.self)
                    let name = try row.firstValue(forColumn: "relname")!.decode(String.self)
                    cache[oid] = name
                }

                let new = PostgreSQLTableNameCache(cache)
                shared.storage[ObjectIdentifier(connection)] = new
                return new
            }
        }
    }
}

/// Stores connection caches per thread.
final class PostgreSQLTableNameCaches {
    /// Psql connection is used as object id.
    var storage: [ObjectIdentifier: PostgreSQLTableNameCache]

    /// Creates a new cache.
    internal init() {
        self.storage = [:]
    }
}
