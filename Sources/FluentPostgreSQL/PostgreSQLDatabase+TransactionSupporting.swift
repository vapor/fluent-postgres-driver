import Async

extension PostgreSQLDatabase: TransactionSupporting {
    /// See `TransactionSupporting.execute(transaction:on:)`
    public static func execute(transaction: DatabaseTransaction<PostgreSQLDatabase>, on connection: PostgreSQLConnection) -> Future<Void> {
        return connection.simpleQuery("BEGIN TRANSACTION").flatMap(to: Void.self) { results in
            return transaction.run(on: connection).flatMap(to: Void.self) { void in
                return connection.simpleQuery("END TRANSACTION").transform(to: ())
            }.flatMapError { error in
                return connection.simpleQuery("ROLLBACK").map(to: Void.self) { results in
                    throw error
                }
            }
        }
    }
}


extension Future {
    func mapError(_ callback: @escaping (Error) -> (Expectation)) -> Future<Expectation> {
        let promise = Promise(Expectation.self)
        addAwaiter { result in
            switch result {
            case .error(let error): promise.complete(callback(error))
            case .expectation(let e): promise.complete(e)
            }
        }
        return promise.future
    }


    func flatMapError(_ callback: @escaping (Error) -> (Future<Expectation>)) -> Future<Expectation> {
        let promise = Promise(Expectation.self)
        addAwaiter { result in
            switch result {
            case .error(let error): callback(error).chain(to: promise)
            case .expectation(let e): promise.complete(e)
            }
        }
        return promise.future
    }
}
