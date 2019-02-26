import FluentBenchmark
import FluentPostgresDriver
import XCTest

final class FluentPostgresDriverTests: XCTestCase {
    var benchmarker: FluentBenchmarker!
    
    func testAll() throws {
        try self.benchmarker.testAll()
    }
    
    func testCreate() throws {
        try self.benchmarker.testCreate()
    }
    
    func testRead() throws {
        try self.benchmarker.testRead()
    }
    
    func testUpdate() throws {
        try self.benchmarker.testUpdate()
    }
    
    func testDelete() throws {
        try self.benchmarker.testDelete()
    }
    
    func testEagerLoadChildren() throws {
        try self.benchmarker.testEagerLoadChildren()
    }
    
    func testEagerLoadParent() throws {
        try self.benchmarker.testEagerLoadParent()
    }
    
    func testEagerLoadParentJoin() throws {
        try self.benchmarker.testEagerLoadParentJoin()
    }
    
    func testEagerLoadSubqueryJSONEncode() throws {
        #warning("TODO: fix connection pool alg")
        try self.benchmarker.testEagerLoadSubqueryJSONEncode()
    }
    
    func testEagerLoadJoinJSONEncode() throws {
        #warning("TODO: fix connection pool alg")
        try self.benchmarker.testEagerLoadJoinJSONEncode()
    }
    
    func testMigrator() throws {
        try self.benchmarker.testMigrator()
    }
    
    func testMigratorError() throws {
        try self.benchmarker.testMigratorError()
    }
    
    func testJoin() throws {
        try self.benchmarker.testJoin()
    }
    
    func testBatchCreate() throws {
        try self.benchmarker.testBatchCreate()
    }
    
    func testBatchUpdate() throws {
        try self.benchmarker.testBatchUpdate()
    }
    
    func testNestedModel() throws {
        try self.benchmarker.testNestedModel()
    }
    
    func testAggregateCount() throws {
        try self.benchmarker.testAggregateCount()
    }
//    
//    func testWorkUnit() throws {
//        try self.benchmarker.testWorkUnit()
//    }
    
    override func setUp() {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        let hostname: String
        #if os(Linux)
        hostname = "psql"
        #else
        hostname = "localhost"
        #endif
        let config = PostgresConfig(
            hostname: hostname,
            port: 5432,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database",
            tlsConfig: nil
        )
        let db = PostgresConnectionSource(config: config, on: eventLoop)
        let pool = ConnectionPool(config: .init(maxConnections: 1), source: db)
        self.benchmarker = FluentBenchmarker(database: pool)
    }
    
    static let allTests = [
        ("testAll", testAll),
    ]
}
