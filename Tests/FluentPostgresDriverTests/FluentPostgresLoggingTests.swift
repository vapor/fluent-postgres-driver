import FluentKit
import InMemoryLogging
import Logging
import SQLKit
import Testing

extension AllSuites {
    @Suite
    struct FluentPostgresLoggingTests {
        init() { #expect(isLoggingConfigured) }

        @Test(arguments: TestDriver.allCases)
        func withConnectionUsesContextLogger(_ driver: TestDriver) async throws {
            try await withDbs(driver) { dbs, _ in
                let (first, second) = try await Self.warmedUpDatabases(dbs)

                try await second.db.withConnection { db in
                    try await (db as! any SQLDatabase).raw("SELECT 'inside withConnection'").run()
                }

                #expect(second.logs.loggedQueries.contains("SELECT 'inside withConnection'"))
                #expect(!first.logs.loggedQueries.contains("SELECT 'inside withConnection'"))
            }
        }

        @Test(arguments: TestDriver.allCases)
        func transactionUsesContextLogger(_ driver: TestDriver) async throws {
            try await withDbs(driver) { dbs, _ in
                let (first, second) = try await Self.warmedUpDatabases(dbs)

                try await second.db.transaction { db in
                    try await (db as! any SQLDatabase).raw("SELECT 'inside transaction'").run()
                }

                #expect(second.logs.loggedQueries.contains("BEGIN"))
                #expect(second.logs.loggedQueries.contains("SELECT 'inside transaction'"))
                #expect(second.logs.loggedQueries.contains("COMMIT"))
                #expect(!first.logs.loggedQueries.contains("SELECT 'inside transaction'"))
            }
        }

        private static func warmedUpDatabases(
            _ dbs: Databases
        ) async throws -> (first: (db: any Database, logs: InMemoryLogHandler), second: (db: any Database, logs: InMemoryLogHandler)) {
            let eventLoop = dbs.eventLoopGroup.any()
            let firstLogs = InMemoryLogHandler.capturingAllLevels(), secondLogs = InMemoryLogHandler.capturingAllLevels()
            let first = dbs.database(.a, logger: Logger(label: "first") { _ in firstLogs }, on: eventLoop)!
            let second = dbs.database(.a, logger: Logger(label: "second") { _ in secondLogs }, on: eventLoop)!

            try await first.withConnection { db in
                try await (db as! any SQLDatabase).raw("SELECT 'warm up'").run()
            }
            return ((first, firstLogs), (second, secondLogs))
        }
    }
}

extension InMemoryLogHandler {
    /// A handler that captures everything, since SQL queries are logged at `.debug` by default.
    static func capturingAllLevels() -> Self {
        var handler = Self()
        handler.logLevel = .trace
        return handler
    }

    /// The SQL of every query that was logged to this handler.
    var loggedQueries: [String] {
        self.entries.compactMap { entry in
            guard case .string(let sql) = entry.metadata["sql"] else { return nil }
            return sql
        }
    }
}
