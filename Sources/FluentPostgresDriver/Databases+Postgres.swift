extension Databases {
    public mutating func postgres(
        config: PostgresConfiguration,
        poolConfig: ConnectionPoolConfig = .init(),
        as id: DatabaseID = .psql,
        isDefault: Bool = true
    ) {
        let db = PostgresConnectionSource(
            configuration: config,
            on: self.eventLoop
        )
        let pool = ConnectionPool(config: poolConfig, source: db)
        self.add(pool, as: id, isDefault: isDefault)
    }
}

extension DatabaseID {
    public static var psql: DatabaseID {
        return .init(string: "psql")
    }
}
