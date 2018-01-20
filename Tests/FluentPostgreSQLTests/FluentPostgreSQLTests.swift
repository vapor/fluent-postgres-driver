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

//    func testNestedStruct() throws {
//        database.logger = DatabaseLogger { print($0) }
//        let conn = try database.makeConnection(using: .init(), on: eventLoop).await(on: eventLoop)
//        try! User.prepare(on: conn).await(on: eventLoop)
//
//        let user = try! User(id: nil, name: "Tanner", pet: Pet(name: "Zizek"))
//            .save(on: conn).await(on: eventLoop)
//
//        let fetched = try! User.query(on: conn).first().await(on: eventLoop)
//        print(fetched?.pet)
//
//        try User.revert(on: conn).await(on: eventLoop)
//        conn.close()
//    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testAutoincrement", testAutoincrement),
    ]
}
//
//struct Pet: Codable, PostgreSQLColumnStaticRepresentable, PostgreSQLDataCustomConvertible {
//    static let postgreSQLColumn = PostgreSQLColumn(type: .jsonb)
//    var name: String
//
//    func convertToPostgreSQLData() throws -> PostgreSQLData {
//        return try .data(JSONEncoder().encode(self))
//    }
//
//    static func convertFromPostgreSQLData(from data: PostgreSQLData) throws -> Pet {
//        switch data {
//        case .data(let data): return try JSONDecoder().decode(Pet.self, from: data)
//        default: fatalError()
//        }
//    }
//}
//
//final class User: PostgreSQLModel, Migration {
//    static let idKey = \User.id
//    var id: Int?
//    var name: String
//    var pet: Pet
//
//    init(id: Int? = nil, name: String, pet: Pet) {
//        self.id = id
//        self.name = name
//        self.pet = pet
//    }
//}

