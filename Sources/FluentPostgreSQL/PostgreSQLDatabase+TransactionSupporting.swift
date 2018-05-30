import Async

extension PostgreSQLDatabase: TransactionSupporting {
    public static func transactionExecute<T>(_ transaction: @escaping (PostgreSQLConnection) throws -> Future<T>, on connection: PostgreSQLConnection) -> Future<T> {
        return connection.simpleQuery("BEGIN TRANSACTION").flatMap(to: T.self) { results in
            return try transaction(connection).flatMap(to: T.self) { res in
                return connection.simpleQuery("END TRANSACTION").transform(to: res)
            }.catchFlatMap { error in
                return connection.simpleQuery("ROLLBACK").map(to: T.self) { results in
                    throw error
                }
            }
        }
    }
}
