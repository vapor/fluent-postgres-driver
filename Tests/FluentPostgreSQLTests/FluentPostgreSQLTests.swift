import Async
import XCTest
import FluentBenchmark
import FluentPostgreSQL

class FluentPostgreSQLTests: XCTestCase {
    var benchmarker: Benchmarker<PostgreSQLDatabase>!
    var worker: EventLoop!

    override func setUp() {
        self.worker = try! DefaultEventLoop(label: "codes.vapor.postgresql.test")
        Thread.async { self.worker.runLoop() }
        let database = PostgreSQLDatabase(config: .default())
        benchmarker = Benchmarker(database, config: .init(), on: worker, onFail: XCTFail)
    }

    func testSchema() throws {
        try! benchmarker.benchmarkSchema().blockingAwait(timeout: .seconds(60))
    }

    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema().blockingAwait(timeout: .seconds(60))
    }

//    func testRelations() throws {
//        try benchmarker.benchmarkRelations_withSchema().blockingAwait(timeout: .seconds(60))
//    }

    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema().blockingAwait(timeout: .seconds(60))
    }

//    func testTransactions() throws {
//        try benchmarker.benchmarkTransactions_withSchema().blockingAwait(timeout: .seconds(60))
//    }

    func testChunking() throws {
        try benchmarker.benchmarkChunking_withSchema().blockingAwait(timeout: .seconds(60))
    }

    func testAutoincrement() throws {
        try benchmarker.benchmarkAutoincrement_withSchema().blockingAwait(timeout: .seconds(60))
    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
//        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
//        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testAutoincrement", testAutoincrement),
    ]
}
