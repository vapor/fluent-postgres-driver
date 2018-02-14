import Async
import XCTest
import FluentBenchmark
import FluentPostgreSQL

class FluentPostgreSQLTests: XCTestCase {
    var benchmarker: Benchmarker<PostgreSQLDatabase>!
    var eventLoop: EventLoop!
    var database: PostgreSQLDatabase!

    override func setUp() {
        eventLoop = try! DefaultEventLoop(label: "codes.vapor.postgresql.test")
        database = PostgreSQLDatabase(config: .default())
        benchmarker = Benchmarker(database, config: .init(), on: eventLoop, onFail: XCTFail)
    }

    func testSchema() throws {
        try benchmarker.benchmarkSchema()
    }

    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema()
    }

    func testRelations() throws {
        try benchmarker.benchmarkRelations_withSchema()
    }

    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema()
    }

    func testTransactions() throws {
        try benchmarker.benchmarkTransactions_withSchema()
    }

    func testChunking() throws {
        try benchmarker.benchmarkChunking_withSchema()
    }

    func testAutoincrement() throws {
        try benchmarker.benchmarkAutoincrement_withSchema()
    }

    func testCache() throws {
        try benchmarker.benchmarkCache_withSchema()
    }

    func testJoins() throws {
        try benchmarker.benchmarkJoins_withSchema()
    }

    func testSoftDeletable() throws {
        try benchmarker.benchmarkSoftDeletable_withSchema()
    }

    func testReferentialActions() throws {
        try benchmarker.benchmarkReferentialActions_withSchema()
    }

    func testNestedStruct() throws {
        /// Swift runtime does not yet support dynamically querying conditional conformance ('Swift.Array<Swift.String>': 'CodableKit.AnyKeyStringDecodable')
        return;
        let conn = try database.makeConnection(using: .init(), on: eventLoop).await(on: eventLoop)
        try User.prepare(on: conn).await(on: eventLoop)
        let user = User(id: nil, name: "Tanner", pet: Pet(name: "Zizek"))
        user.favoriteColors = ["pink", "blue"]
        user.dict["hello"] = "world"
        _ = try user.save(on: conn).await(on: eventLoop)
        if let fetched = try User.query(on: conn).first().await(on: eventLoop) {
            XCTAssertEqual(user.id, fetched.id)
            XCTAssertNil(user.age)
            XCTAssertEqual(fetched.favoriteColors, ["pink", "blue"])
            XCTAssertEqual(fetched.dict["hello"], "world")
        } else {
            XCTFail()
        }

        try User.revert(on: conn).await(on: eventLoop)
        conn.close()
    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testAutoincrement", testAutoincrement),
        ("testCache", testCache),
        ("testJoins", testJoins),
        ("testSoftDeletable", testSoftDeletable),
        ("testReferentialActions", testReferentialActions),
    ]
}

struct Pet: PostgreSQLJSONType {
    var name: String
}

final class User: PostgreSQLModel, Migration {
    static let idKey: WritableKeyPath<User, Int?> = \User.id
    var id: Int?
    var name: String
    var age: Int?
    var favoriteColors: [String]
    var pet: Pet
    var dict: [String: String]

    init(id: Int? = nil, name: String, pet: Pet) {
        self.favoriteColors = []
        self.dict = [:]
        self.id = id
        self.name = name
        self.pet = pet
    }
}

