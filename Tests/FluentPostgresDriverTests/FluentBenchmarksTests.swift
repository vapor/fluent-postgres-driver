import FluentBenchmark
import FluentKit
import FluentPostgresDriver
import FluentSQL
import Logging
import PostgresKit
import SQLKit
import XCTest
import PostgresNIO

final class FluentBenchmarksTests: XCTestCase {
    var benchmarker: FluentBenchmarker { .init(databases: self.dbs) }
    var dbs: Databases!

    private var driver: TestDriver = .asyncKit

     override func invokeTest() {
        for driver in TestDriver.allCases {
            self.driver = driver
            super.invokeTest()
        }
    }

    override func setUp() async throws {
        try await super.setUp()

        XCTAssert(isLoggingConfigured)
        self.dbs = Databases(threadPool: .singleton, on: MultiThreadedEventLoopGroup.singleton)

        switch self.driver {
        case .asyncKit:
            self.dbs.use(.testPostgres(subconfig: "A"), as: .a)
            self.dbs.use(.testPostgres(subconfig: "B"), as: .b)
        case .postgresClient:
            guard #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) else { throw XCTSkip("PostgresClient unavailable") }
            self.dbs.use(.testPostgres(clientSubconfig: "A", logger: .init(label: "test.fluent.a")), as: .a)
            self.dbs.use(.testPostgres(clientSubconfig: "B", logger: .init(label: "test.fluent.b")), as: .b)
        }

        for (id, label) in [(DatabaseID.a, "test.fluent.a"), (.b, "test.fluent.b")] {
            let sql = self.dbs.database(id, logger: .init(label: label), on: self.dbs.eventLoopGroup.any()) as! any SQLDatabase
            try await sql.raw("drop schema public cascade").run()
            try await sql.raw("create schema public").run()
        }
    }

    override func tearDown() async throws {
        await self.dbs.shutdownAsync()
        try await super.tearDown()
    }

    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
    func testChild() throws { try self.benchmarker.testChildren() }
    func testChildren() throws { try self.benchmarker.testChildren() }
    func testChunk() throws { try self.benchmarker.testChunk() }
    func testCodable() throws { try self.benchmarker.testCodable() }
    func testCompositeID() throws { try self.benchmarker.testCompositeID() }
    func testCRUD() throws { try self.benchmarker.testCRUD() }
    func testEagerLoad() throws { try self.benchmarker.testEagerLoad() }
    func testEnum() throws { try self.benchmarker.testEnum() }
    func testFilter() throws { try self.benchmarker.testFilter() }
    func testGroup() throws { try self.benchmarker.testGroup() }
    func testID() throws { try self.benchmarker.testID() }
    func testJoin() throws { try self.benchmarker.testJoin() }
    func testMiddleware() throws { try self.benchmarker.testMiddleware() }
    func testMigrator() throws { try self.benchmarker.testMigrator() }
    func testModel() throws { try self.benchmarker.testModel() }
    func testOptionalParent() throws { try self.benchmarker.testOptionalParent() }
    func testPagination() throws { try self.benchmarker.testPagination() }
    func testParent() throws { try self.benchmarker.testParent() }
    func testPerformance() throws { try self.benchmarker.testPerformance() }
    func testRange() throws { try self.benchmarker.testRange() }
    func testSchema() throws { try self.benchmarker.testSchema() }
    func testSet() throws { try self.benchmarker.testSet() }
    func testSiblings() throws { try self.benchmarker.testSiblings() }
    func testSoftDelete() throws { try self.benchmarker.testSoftDelete() }
    func testSort() throws { try self.benchmarker.testSort() }
    func testSQL() throws { try self.benchmarker.testSQL() }
    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
    func testTransaction() throws { try self.benchmarker.testTransaction() }
    func testUnique() throws { try self.benchmarker.testUnique() }
}
