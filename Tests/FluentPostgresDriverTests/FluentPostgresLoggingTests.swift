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

        @Test(.bug("https://github.com/vapor/fluent-postgres-driver/issues/230"), arguments: TestDriver.allCases)
        func transactionLogsIncludeConnectionID(_ driver: TestDriver) async throws {
            try await withDbs(driver) { dbs, _ in
                let (_, second) = try await Self.warmedUpDatabases(dbs)

                try await second.db.transaction { db in
                    try await (db as! any SQLDatabase).raw("SELECT 'inside transaction'").run()
                }

                let metadata = ["BEGIN", "SELECT 'inside transaction'", "COMMIT"].map { second.logs.metadata(forQuery: $0) }

                // Every query in the transaction ran on the same connection
                let connectionIDs = metadata.map { $0?["psql_connection_id"] }
                #expect(connectionIDs[0] != nil)
                #expect(connectionIDs.allSatisfy { $0 == connectionIDs[0] })

                // It should have it's own context though
                #expect(metadata.allSatisfy { $0?["request-id"] == "second" })
            }
        }

        private static func warmedUpDatabases(
            _ dbs: Databases
        ) async throws -> (first: (db: any Database, logs: InMemoryLogHandler), second: (db: any Database, logs: InMemoryLogHandler)) {
            let eventLoop = dbs.eventLoopGroup.any()
            let firstLogs = InMemoryLogHandler.capturingAllLevels(), secondLogs = InMemoryLogHandler.capturingAllLevels()
            var firstLogger = Logger(label: "first") { _ in firstLogs }, secondLogger = Logger(label: "second") { _ in secondLogs }
            firstLogger[metadataKey: "request-id"] = "first"
            secondLogger[metadataKey: "request-id"] = "second"
            let first = dbs.database(.a, logger: firstLogger, on: eventLoop)!
            let second = dbs.database(.a, logger: secondLogger, on: eventLoop)!

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

    /// The metadata that was logged alongside the given query, if it was logged to this handler.
    func metadata(forQuery sql: String) -> Logger.Metadata? {
        self.entries.first { $0.metadata["sql"] == .string(sql) }?.metadata
    }
}
