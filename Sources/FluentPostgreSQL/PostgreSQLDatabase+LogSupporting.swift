extension PostgreSQLDatabase: LogSupporting {
    /// See `LogSupporting.enableLogging(using:)`
    public func enableLogging(using logger: DatabaseLogger) {
        self.logger = logger
    }
}

extension DatabaseLogger: PostgreSQLLogger {
    /// See `PostgreSQLLogger.log(query:parameters:)`
    public func log(query: String, parameters: [PostgreSQLData]) {
        let log = DatabaseLog(query: query, values: parameters.map { $0.data?.description ?? "nil" }, dbID: "postgresql", date: .init())
        self.record(log: log)
    }
}
