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
    override func setUp() async throws {
        try await super.setUp()
        XCTAssert(isLoggingConfigured)
    }

    private func forEachDriver(_ body: @escaping @Sendable (FluentBenchmarker) throws -> Void) async throws {
        for driver in TestDriver.allCases {
            try await withDbs(driver) { dbs, _ in try body(FluentBenchmarker(databases: dbs)) }
        }
    }

    func testAggregate() async throws { try await self.forEachDriver { try $0.testAggregate() } }
    func testArray() async throws { try await self.forEachDriver { try $0.testArray() } }
    func testBatch() async throws { try await self.forEachDriver { try $0.testBatch() } }
    func testChild() async throws { try await self.forEachDriver { try $0.testChildren() } }
    func testChildren() async throws { try await self.forEachDriver { try $0.testChildren() } }
    func testChunk() async throws { try await self.forEachDriver { try $0.testChunk() } }
    func testCodable() async throws { try await self.forEachDriver { try $0.testCodable() } }
    func testCompositeID() async throws { try await self.forEachDriver { try $0.testCompositeID() } }
    func testCRUD() async throws { try await self.forEachDriver { try $0.testCRUD() } }
    func testEagerLoad() async throws { try await self.forEachDriver { try $0.testEagerLoad() } }
    func testEnum() async throws { try await self.forEachDriver { try $0.testEnum() } }
    func testFilter() async throws { try await self.forEachDriver { try $0.testFilter() } }
    func testGroup() async throws { try await self.forEachDriver { try $0.testGroup() } }
    func testID() async throws { try await self.forEachDriver { try $0.testID() } }
    func testJoin() async throws { try await self.forEachDriver { try $0.testJoin() } }
    func testMiddleware() async throws { try await self.forEachDriver { try $0.testMiddleware() } }
    func testMigrator() async throws { try await self.forEachDriver { try $0.testMigrator() } }
    func testModel() async throws { try await self.forEachDriver { try $0.testModel() } }
    func testOptionalParent() async throws { try await self.forEachDriver { try $0.testOptionalParent() } }
    func testPagination() async throws { try await self.forEachDriver { try $0.testPagination() } }
    func testParent() async throws { try await self.forEachDriver { try $0.testParent() } }
    func testPerformance() async throws { try await self.forEachDriver { try $0.testPerformance() } }
    func testRange() async throws { try await self.forEachDriver { try $0.testRange() } }
    func testSchema() async throws { try await self.forEachDriver { try $0.testSchema() } }
    func testSet() async throws { try await self.forEachDriver { try $0.testSet() } }
    func testSiblings() async throws { try await self.forEachDriver { try $0.testSiblings() } }
    func testSoftDelete() async throws { try await self.forEachDriver { try $0.testSoftDelete() } }
    func testSort() async throws { try await self.forEachDriver { try $0.testSort() } }
    func testSQL() async throws { try await self.forEachDriver { try $0.testSQL() } }
    func testTimestamp() async throws { try await self.forEachDriver { try $0.testTimestamp() } }
    func testTransaction() async throws { try await self.forEachDriver { try $0.testTransaction() } }
    func testUnique() async throws { try await self.forEachDriver { try $0.testUnique() } }
}
