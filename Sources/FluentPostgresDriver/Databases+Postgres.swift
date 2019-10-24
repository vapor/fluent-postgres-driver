extension Databases {
    public func postgres(
        configuration: PostgresConfiguration,
        poolConfiguration: ConnectionPoolConfiguration = .init(),
        as id: DatabaseID = .psql,
        isDefault: Bool = true,
        on eventLoopGroup: EventLoopGroup
    ) {
        let db = PostgresConnectionSource(
            configuration: configuration
        )
        let pool = ConnectionPool(
            configuration: poolConfiguration,
            source: db,
            on: eventLoopGroup
        )
        self.add(PostgresDatabaseDriver(pool: pool), as: id, isDefault: isDefault)
    }
}

extension DatabaseID {
    public static var psql: DatabaseID {
        return .init(string: "psql")
    }
}
