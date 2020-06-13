extension PostgreSQLDatabase: TransactionSupporting {
    /// See `TransactionSupporting`.
    public static func transactionExecute<T>(_ transaction: @escaping (PostgreSQLConnection) throws -> Future<T>, on connection: PostgreSQLConnection) -> Future<T> {
        func rollback(error: Error) -> Future<T> {
            return connection.simpleQuery("ROLLBACK").map { throw error }
        }

        return connection.simpleQuery("BEGIN TRANSACTION").flatMap { results in
            return try transaction(connection).flatMap { res in
                return connection.simpleQuery("END TRANSACTION").transform(to: res)
            }.catchFlatMap(rollback)
        }.catchFlatMap(rollback)
    }
}
