import Async

extension PostgreSQLDatabase: TransactionSupporting {
    /// See `TransactionSupporting.execute(transaction:on:)`
    public static func execute(transaction: DatabaseTransaction<PostgreSQLDatabase>, on connection: PostgreSQLConnection) -> Future<Void> {
        return connection.simpleQuery("BEGIN TRANSACTION").flatMap(to: Void.self) { results in
            return transaction.run(on: connection).flatMap(to: Void.self) { void in
                return connection.simpleQuery("END TRANSACTION").transform(to: ())
            }.catchFlatMap { error in
                return connection.simpleQuery("ROLLBACK").map(to: Void.self) { results in
                    throw error
                }
            }
        }
    }
}
