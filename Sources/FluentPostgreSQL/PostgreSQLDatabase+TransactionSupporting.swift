import Async

extension PostgreSQLDatabase: TransactionSupporting {
    /// See `TransactionSupporting.execute(transaction:on:)`
    public static func execute<R>(transaction: DatabaseTransaction<PostgreSQLDatabase, R>, on connection: PostgreSQLConnection) -> Future<R> {
        return connection.simpleQuery("BEGIN TRANSACTION").flatMap(to: R.self) { results in
            return transaction.run(on: connection).flatMap(to: R.self) { result in
                return connection.simpleQuery("END TRANSACTION").transform(to: result)
            }.catchFlatMap { error in
                return connection.simpleQuery("ROLLBACK").map(to: R.self) { results in
                    throw error
                }
            }
        }
    }
}
