import Async
import Core
import XCTest
import FluentBenchmark
import FluentPostgreSQL
import Foundation

class FluentPostgreSQLTests: XCTestCase {
    var benchmarker: Benchmarker<PostgreSQLDatabase>!
    var database: PostgreSQLDatabase!

    override func setUp() {
        let hostname: String
        #if Xcode
        hostname = (try? Process.execute("docker-machine", "ip")) ?? "192.168.99.100"
        #else
        hostname = "localhost"
        #endif

        let config = PostgreSQLDatabaseConfig(
            hostname: hostname,
            port: 5432,
            username: "vapor_username",
            database: "vapor_database",
            password: nil
        )
        let main = MultiThreadedEventLoopGroup(numThreads: 1)
        database = PostgreSQLDatabase(config: config, on: main)
        let eventLoop = MultiThreadedEventLoopGroup(numThreads: 1)
        benchmarker = Benchmarker(database, on: eventLoop, onFail: XCTFail)
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
        let conn = try benchmarker.pool.requestConnection().wait()
        try? User.revert(on: conn).wait()
        try User.prepare(on: conn).wait()
        let user = User(id: nil, name: "Tanner", pet: Pet(name: "Zizek"))
        user.favoriteColors = ["pink", "blue"]
        _ = try user.save(on: conn).wait()
        if let fetched = try User.query(on: conn).first().wait() {
            XCTAssertEqual(user.id, fetched.id)
            XCTAssertNil(user.age)
            XCTAssertEqual(fetched.favoriteColors, ["pink", "blue"])
        } else {
            XCTFail()
        }
        try User.revert(on: conn).wait()
        benchmarker.pool.releaseConnection(conn)
    }

    func testIndexSupporting() throws {
        try benchmarker.benchmarkIndexSupporting_withSchema()
    }

    func testMinimumViableModelDeclaration() throws {
        /// NOTE: these must never fail to build
        struct Foo: PostgreSQLModel {
            var id: Int?
            var name: String
        }
        final class Bar: PostgreSQLModel {
            var id: Int?
            var name: String
        }
        struct Baz: PostgreSQLUUIDModel {
            var id: UUID?
            var name: String
        }
        final class Qux: PostgreSQLUUIDModel {
            var id: UUID?
            var name: String
        }
    }

    func testDefaultValue() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? DefaultTest.revert(on: conn).wait() }
        try DefaultTest.prepare(on: conn).wait()
        let test = DefaultTest()
        // _ = try test.save(on: conn).await(on: eventLoop)
        let builder = test.query(on: conn)
        builder.query.data = try ["foo": "bar".convertToPostgreSQLData()] // there _must_ be a better way
        builder.query.action = .create
        try builder.run().wait()
        if let fetched = try DefaultTest.query(on: conn).first().wait() {
            XCTAssertNotNil(fetched.date?.value)
        } else {
            XCTFail()
        }
        benchmarker.pool.releaseConnection(conn)
    }


    func testUpdate() throws {
        benchmarker.database.enableLogging(using: .print)
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? User.revert(on: conn).wait() }
        try User.prepare(on: conn).wait()
        let user = User(id: nil, name: "Tanner", pet: Pet(name: "Zizek"))
        user.favoriteColors = ["pink", "blue"]
        _ = try user.save(on: conn).wait()
        try User.query(on: conn).update(["name": "Vapor"]).wait()
        benchmarker.pool.releaseConnection(conn)
    }

    func testGH24() throws {
        benchmarker.database.enableLogging(using: .print)
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? Allergy.revert(on: conn).wait() }
        try Allergy.prepare(on: conn).wait()
        struct Allergy: PostgreSQLModel, Migration {
            static let entity = "allergies"
            var id: Int?
        }
        _ = try Allergy(id: 2).create(on: conn).wait()
        _ = try Allergy(id: 4).create(on: conn).wait()
        let stuff = try Allergy.query(on: conn).filter(\Allergy.id, in: [1, 2, 3]).all().wait()
        XCTAssertEqual(stuff.count, 1)
        XCTAssertEqual(stuff.first?.id, 2)
    }

    func testGH21() throws {
        /// - types
        enum PetType: Int, PostgreSQLEnumType {
            static let keyString: TupleMap = (.cat, .dog)
            case cat = 1
            case dog = 2
        }
        struct Pet: PostgreSQLModel, Migration {
            static let entity = "pets"
            var id: Int?
            var type: PetType
            var name: String
        }

        /// - prepare db
        benchmarker.database.enableLogging(using: .print)
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? Pet.revert(on: conn).wait() }
        try Pet.prepare(on: conn).wait()

        /// - tests
        _ = try Pet(id: nil, type: .cat, name: "Ziz").save(on: conn).wait()
        _ = try Pet(id: nil, type: .dog, name: "Spud").save(on: conn).wait()
        let cats = try Pet.query(on: conn).filter(\.type == .cat).all().wait()
        let dogs = try Pet.query(on: conn).filter(\.type == .dog).all().wait()
        XCTAssertEqual(cats.count, 1)
        XCTAssertEqual(cats.first?.name, "Ziz")
        XCTAssertEqual(dogs.count, 1)
        XCTAssertEqual(dogs.first?.name, "Spud")
    }
    
    func testPersistsDateMillisecondPart() throws {
        database.enableLogging(using: DatabaseLogger(handler: { print($0) }))
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? DefaultTest.revert(on: conn).wait() }
        try DefaultTest.prepare(on: conn).wait()
        var test = DefaultTest()
        test.date = PostgreSQLDate(Date(timeIntervalSinceReferenceDate: 123.456))
        _ = try test.save(on: conn).wait()
        let fetched = try DefaultTest.query(on: conn).first().wait()!
        XCTAssertEqual(123.456, fetched.date!.value!.timeIntervalSinceReferenceDate, accuracy: 1e-6)
    }

    func testContains() throws {
        try benchmarker.benchmarkContains_withSchema()
    }

    func testGH30() throws {
        /// - types
        struct Foo: PostgreSQLModel, Migration {
            static let entity = "foos"
            var id: Int?
            var location: PostgreSQLPoint?
        }

        /// - prepare db
        benchmarker.database.enableLogging(using: .print)
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? Foo.revert(on: conn).wait() }
        try Foo.prepare(on: conn).wait()

        /// - tests
        var foo = Foo(id: nil, location: PostgreSQLPoint(x: 1, y: 3.14))
        foo = try foo.save(on: conn).wait()
        foo = try Foo.find(foo.requireID(), on: conn).wait()!
        XCTAssertEqual(foo.location?.x, 1)
        XCTAssertEqual(foo.location?.y, 3.14)
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
        ("testIndexSupporting", testIndexSupporting),
        ("testMinimumViableModelDeclaration", testMinimumViableModelDeclaration),
        ("testGH24", testGH24),
        ("testGH21", testGH21),
        ("testPersistsDateMillisecondPart", testPersistsDateMillisecondPart),
        ("testContains", testContains),
        ("testGH30", testGH30),
    ]
}

struct PostgreSQLDate: PostgreSQLType, Codable {
    static var postgreSQLDataType: PostgreSQLDataType {
        return .timestamp
    }

    static var postgreSQLDataArrayType: PostgreSQLDataType {
        return ._timestamp
    }

    static var postgreSQLColumn: PostgreSQLColumn {
        return PostgreSQLColumn(type: .timestamp, size: nil, default: "CURRENT_TIMESTAMP")
    }

    var value: Date?

    init(_ value: Date? = nil) {
        self.value = value
    }

    static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> PostgreSQLDate {
        return try PostgreSQLDate(Date.convertFromPostgreSQLData(data))
    }

    func convertToPostgreSQLData() throws -> PostgreSQLData {
        return try value?.convertToPostgreSQLData() ?? PostgreSQLData(type: .timestamp, format: .binary, data: nil)
    }
}

struct DefaultTest: PostgreSQLModel, Migration {
    var id: Int?
    var date: PostgreSQLDate?
    var foo: String
    init() {
        self.id = nil
        self.date = nil
        self.foo = "bar'"
    }
}

struct Pet: PostgreSQLJSONType, Codable {
    var name: String
}

final class User: PostgreSQLModel, Migration {
    static let idKey: WritableKeyPath<User, Int?> = \User.id
    var id: Int?
    var name: String
    var age: Int?
    var favoriteColors: [String]
    var pet: Pet

    init(id: Int? = nil, name: String, pet: Pet) {
        self.favoriteColors = []
        self.id = id
        self.name = name
        self.pet = pet
    }
}

