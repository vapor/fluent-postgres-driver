import Testing
import FluentPostgresDriver
import InMemoryLogging
import ServiceLifecycle

extension AllSuites {

@Suite
struct FluentPostgresClientDriverTests {
    @Test
    func externalClientSurvivesDatabasesShutdown() async throws {
        let client = PostgresClient(configuration: .test(subconfig: "A"), eventLoopGroup: MultiThreadedEventLoopGroup.singleton, backgroundLogger: .init(label: "x"))
        let group = ServiceGroup(services: [client], logger: .init(label: "x"))
        let run = Task { try await group.run() }

        let dbs = Databases(threadPool: .singleton, on: MultiThreadedEventLoopGroup.singleton)
        dbs.use(.postgres(client: client, logger: .init(label: "x")), as: .a)
        let db = dbs.database(.a, logger: .init(label: "x"), on: dbs.eventLoopGroup.any())!
        try await (db as! any SQLDatabase).raw("SELECT 1").run()
        await dbs.shutdownAsync()

        // Fluent is gone, the client is still ours
        _ = try await client.query("SELECT 1").collect()

        await group.triggerGracefulShutdown()
        _ = try? await run.value
    }

    @Test(arguments: TestDriver.clientDrivers)
    func transactionControlRequiresConnection(_ driver: TestDriver) async throws {
        try await withDbs(driver) { _, db in
            let error = await #expect(throws: FluentPostgresError.self) {
                try await (db as! any TransactionControlDatabase).beginTransaction().get()
            }
            #expect(error == .transactionControlRequiresConnection)
        }
    }

    @Test(arguments: TestDriver.clientDrivers)
    func nestedTransactionInsideWithConnectionIsNoOp(_ driver: TestDriver) async throws {
        try await withDbs(driver) { dbs, _ in
            let logs = InMemoryLogHandler.capturingAllLevels()
            let db = dbs.database(.a, logger: Logger(label: "nested") { _ in logs }, on: dbs.eventLoopGroup.any())!
            try await db.withConnection { conn in
                try await conn.transaction { outer in
                    try await outer.transaction { inner in
                        try await (inner as! any SQLDatabase).raw("SELECT 1").run()
                    }
                }
            }
            #expect(logs.loggedQueries.filter { $0 == "BEGIN" }.count == 1)
            #expect(logs.loggedQueries.filter { $0 == "COMMIT" }.count == 1)
        }
    }

    @Test(arguments: TestDriver.clientDrivers)
    func withSessionPinsOneConnection(_ driver: TestDriver) async throws {
        try await withDbs(driver) { _, db in
            let pids = try await (db as! any SQLDatabase).withSession { sql in
                try await (
                    sql.raw("SELECT pg_backend_pid() AS pid").first(decodingColumn: "pid", as: Int.self),
                    sql.raw("SELECT pg_backend_pid() AS pid").first(decodingColumn: "pid", as: Int.self)
                )
            }
            #expect(pids.0 == pids.1)
        }
    }
}

}
