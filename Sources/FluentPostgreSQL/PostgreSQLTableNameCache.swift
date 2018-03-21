import Async

/// Caches table OID to string name associations.
final class PostgreSQLTableNameCache {
    /// The internal cache.
    var storage: [Int32: String]

    /// Static shared cache, stored by connections.
    private static var shared: [ObjectIdentifier: PostgreSQLTableNameCache] = [:]

    /// Creates a new cache.
    private init(cache: [Int32: String]) {
        self.storage = cache
    }

    /// Invalidates the cache for the supplied connection.
    static func invalidate(for connection: PostgreSQLConnection) {
        shared[ObjectIdentifier(connection)] = nil
    }

    /// Generates a cache for the supplied connection.
    static func get(for connection: PostgreSQLConnection) -> Future<PostgreSQLTableNameCache> {
        if let existing = shared[ObjectIdentifier(connection)] {
            return Future.map(on: connection) { existing }
        } else {
            return connection.simpleQuery("select oid, relname from pg_class").map(to: PostgreSQLTableNameCache.self) { rows in
                var cache: [Int32: String] = [:]

                for row in rows {
                    let oid = try row.firstValue(forColumn: "oid")!.decode(Int32.self)
                    let name = try row.firstValue(forColumn: "relname")!.decode(String.self)
                    cache[oid] = name
                }

                let new = PostgreSQLTableNameCache(cache: cache)
                shared[ObjectIdentifier(connection)] = new
                return new
            }
        }
    }
}
