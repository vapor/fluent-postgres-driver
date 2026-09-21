import NIOCore

struct UnsafeTransfer<Value>: @unchecked Sendable {
    var wrappedValue: Value

    init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension EventLoop {
    /// Like `makeFutureWithTask(_:)`, but without requiring the result type to be `Sendable`.
    func makeFutureWithUnsafeTask<T>(
        _ body: @escaping @Sendable () async throws -> T
    ) -> EventLoopFuture<T> {
        let promise = UnsafeTransfer(self.makePromise(of: T.self))

        Task {
            let result: Result<UnsafeTransfer<T>, any Error>
            do {
                result = .success(UnsafeTransfer(try await body()))
            } catch {
                result = .failure(error)
            }
            self.execute {
                switch result {
                case .success(let value):
                    promise.wrappedValue.assumeIsolated().succeed(value.wrappedValue)
                case .failure(let error):
                    promise.wrappedValue.fail(error)
                }
            }
        }
        return promise.wrappedValue.futureResult
    }
}

extension EventLoopFuture {
    /// Like `get()`, but without requiring `Value` to be `Sendable`.
    func unsafeGet() async throws -> Value {
        try await self.map { UnsafeTransfer($0) }.get().wrappedValue
    }
}
