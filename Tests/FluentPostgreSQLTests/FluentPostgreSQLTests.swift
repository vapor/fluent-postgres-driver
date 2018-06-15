import Async
import Core
import XCTest
import FluentBenchmark
import FluentPostgreSQL
import Fluent
import Foundation

class FluentPostgreSQLTests: XCTestCase {
    var benchmarker: Benchmarker<PostgreSQLDatabase>!
    var database: PostgreSQLDatabase!

    override func setUp() {
        #if os(macOS)
        let hostname = "localhost"
        #else
        let hostname = "psql-cleartext"
        #endif
        
        let config: PostgreSQLDatabaseConfig = .init(
            hostname: hostname,
            port: 5432,
            username: "vapor_username",
            database: "vapor_database",
            password: "vapor_password"
        )
        database = PostgreSQLDatabase(config: config)
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        benchmarker = try! Benchmarker(database, on: eventLoop, onFail: XCTFail)
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
        var user = User(id: nil, name: "Tanner", pet: Pet(name: "Zizek"))
        user.favoriteColors = ["pink", "blue"]
        user = try user.save(on: conn).wait()
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

//    func testDefaultValue() throws {
//        let conn = try benchmarker.pool.requestConnection().wait()
//        defer { try? DefaultTest.revert(on: conn).wait() }
//        try DefaultTest.prepare(on: conn).wait()
//        let test = DefaultTest()
//        // _ = try test.save(on: conn).await(on: eventLoop)
//        let builder = test.query(on: conn)
//        builder.query.data = try ["foo": "bar".convertToPostgreSQLData()] // there _must_ be a better way
//        builder.query.action = .create
//        try builder.run().wait()
//        if let fetched = try DefaultTest.query(on: conn).first().wait() {
//            XCTAssertNotNil(fetched.date?.value)
//        } else {
//            XCTFail()
//        }
//        benchmarker.pool.releaseConnection(conn)
//    }


    func testUpdate() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? User.revert(on: conn).wait() }
        try User.prepare(on: conn).wait()
        let user = User(id: nil, name: "Tanner", pet: Pet(name: "Zizek"))
        user.favoriteColors = ["pink", "blue"]
        _ = try user.save(on: conn).wait()
        try User.query(on: conn).update(data: ["name": "Vapor"]).wait()
        benchmarker.pool.releaseConnection(conn)
    }

    func testGH24() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? Allergy.revert(on: conn).wait() }
        try Allergy.prepare(on: conn).wait()
        struct Allergy: PostgreSQLModel, Migration {
            static let entity = "allergies"
            var id: Int?
        }
        _ = try Allergy(id: 2).create(on: conn).wait()
        _ = try Allergy(id: 4).create(on: conn).wait()
        let stuff = try Allergy.query(on: conn).filter(\.id ~~ [1, 2, 3]).all().wait()
        XCTAssertEqual(stuff.count, 1)
        XCTAssertEqual(stuff.first?.id, 2)
    }

    func testGH21() throws {
        /// - types
        enum PetType: Int, CaseIterable, ReflectionDecodable, Codable {
            static let allCases: [PetType] = [.cat, .dog]
            case cat = 0
            case dog = 1
        }
        struct Pet: PostgreSQLModel, Migration {
            static let entity = "pets"
            var id: Int?
            var type: PetType
            var name: String
            
            static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
                return PostgreSQLDatabase.create(Pet.self, on: conn) { builder in
                    builder.field(for: \.id, isIdentifier: true)
                    builder.field(for: \.type, type: .bigint)
                    builder.field(for: \.name, type: .text)
                }
            }
        }

        try print(Pet.reflectProperties())

        /// - prepare db
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
        struct DefaultTest: PostgreSQLModel, Migration {
            var id: Int?
            var date: Date?
            var foo: String
            init() {
                self.id = nil
                self.date = nil
                self.foo = "bar"
            }
            static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
                return PostgreSQLDatabase.create(DefaultTest.self, on: conn) { builder in
                    builder.field(for: \.id, isIdentifier: true)
                    builder.field(.init(name: "date", dataType: .timestamp(nil), constraints: [
                        .default(.function("current_timestamp"))
                    ]))
                    builder.field(for: \.foo)
                }
            }
        }
        
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { try? DefaultTest.revert(on: conn).wait() }
        try DefaultTest.prepare(on: conn).wait()
        _ = try DefaultTest().save(on: conn).wait()
        let fetched = try DefaultTest.query(on: conn).first().wait()!
        // within 1 minute
        XCTAssertEqual(Date().timeIntervalSinceReferenceDate, fetched.date!.timeIntervalSinceReferenceDate, accuracy: 60)
    }

    func testGH30() throws {
        /// - types
        struct Foo: PostgreSQLModel, Migration {
            static let entity = "foos"
            var id: Int?
            var location: PostgreSQLPoint?
        }

        /// - prepare db
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

    func testBugs() throws {
        try benchmarker.benchmarkBugs_withSchema()
    }
    
    func testCodableSimple() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        _ = try conn.simpleQuery("create table users (id int, name text)").wait()
        defer { _ = try! conn.simpleQuery("drop table users").wait() }
        
        struct SimpleUser: Codable {
            var id: Int
            var name: String
        }

        try XCTAssertEqual(SimpleUser.query("users", on: conn).count().wait(), 0)
        
        let user = SimpleUser(id: 1, name: "Vapor")
        try SimpleUser.query("users", on: conn).create(data: user).wait()
        
        try XCTAssertEqual(SimpleUser.query("users", on: conn).count().wait(), 1)
        try XCTAssertEqual(SimpleUser.query("users", on: conn).all().wait().count, 1)
        
        
        struct SimpleUserComputed: Codable {
            var id: Int
            var name: String
            var computed: String
        }

        let res = try SimpleUserComputed
            .query("users", on: conn)
            .keys("id", "name", .expression(.function(.init(name: "md5", parameters: ["name"])), alias: "computed"))
            .all()
            .wait()
        
        print(res)
    }
    
    // https://github.com/vapor/fluent-postgresql/issues/32
    func testURL() throws {
        struct User: PostgreSQLModel, Migration {
            static let entity = "users"
            var id: Int?
            var name: String
            var website: URL
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        var user = User(id: nil, name: "Tanner", website: URL(string: "http://tanner.xyz")!)
        user = try user.save(on: conn).wait()
        
        let fetched = try User.find(1, on: conn).wait()
        XCTAssertEqual(fetched?.website.absoluteString, "http://tanner.xyz")
    }
    
    func testDocs_type() throws {
        enum PlanetType: String, PostgreSQLEnum, PostgreSQLMigration {
            static let postgreSQLEnumTypeName = "PLANET_TYPE"
            static let allCases: [PlanetType] = [.smallRocky, .gasGiant, .dwarf]
            case smallRocky
            case gasGiant
            case dwarf
        }

        struct Planet: PostgreSQLModel, PostgreSQLMigration {
            var id: Int?
            let name: String
            let type: PlanetType
            
            static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
                return PostgreSQLDatabase.create(Planet.self, on: conn) { builder in
                    builder.field(for: \.id)
                    builder.field(for: \.name, type: .varchar(64))
                    builder.field(for: \.type)
                }
            }
        }

        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        try PlanetType.prepare(on: conn).wait()
        // try PostgreSQLDatabase.alter(enum: PlanetType.self, add: .dwarf, on: conn).wait()
        defer { try? PlanetType.revert(on: conn).wait() }
        try Planet.prepare(on: conn).wait()
        defer { try? Planet.revert(on: conn).wait() }

        let rows = try Planet.query(on: conn).filter(\.type == .gasGiant).all().wait()
        XCTAssertEqual(rows.count, 0)
    }
    
    func testContains() throws {
        struct User: PostgreSQLModel, PostgreSQLMigration {
            var id: Int?
            var name: String
            var age: Int
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        
        try User.prepare(on: conn).wait()
        defer { try! User.revert(on: conn).wait() }
        
        // create
        let tanner1 = User(id: nil, name: "tanner", age: 23)
        _ = try tanner1.save(on: conn).wait()
        let tanner2 = User(id: nil, name: "ner", age: 23)
        _ = try tanner2.save(on: conn).wait()
        let tanner3 = User(id: nil, name: "tan", age: 23)
        _ = try tanner3.save(on: conn).wait()
        
        let tas = try User.query(on: conn).filter(\.name =~ "ta").count().wait()
        if tas != 2 {
            XCTFail("tas == \(tas)")
        }
//        let ers = try User.query(on: conn).filter(\.name ~= "er").count().wait()
//        if ers != 2 {
//            XCTFail("ers == \(tas)")
//        }
        let annes = try User.query(on: conn).filter(\.name ~~ "anne").count().wait()
        if annes != 1 {
            XCTFail("annes == \(tas)")
        }
        let ns = try User.query(on: conn).filter(\.name ~~ "n").count().wait()
        if ns != 3 {
            XCTFail("ns == \(tas)")
        }
        
        let nertan = try User.query(on: conn).filter(\.name ~~ ["ner", "tan"]).count().wait()
        if nertan != 2 {
            XCTFail("nertan == \(tas)")
        }
        
        let notner = try User.query(on: conn).filter(\.name !~ ["ner"]).count().wait()
        if notner != 2 {
            XCTFail("nertan == \(tas)")
        }
    }
    
    func testEmptySubset() throws {
        struct User: PostgreSQLModel, PostgreSQLMigration {
            var id: Int?
        }
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try User.prepare(on: conn).wait()
        defer { _ = try? User.revert(on: conn).wait() }

        let res = try User.query(on: conn).filter(\.id ~~ []).all().wait()
        XCTAssertEqual(res.count, 0)
        _ = try User.query(on: conn).filter(\.id ~~ [1]).all().wait()
        _ = try User.query(on: conn).filter(\.id ~~ [1, 2]).all().wait()
        _ = try User.query(on: conn).filter(\.id ~~ [1, 2, 3]).all().wait()
    }
    
    func testSort() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try Planet.prepare(on: conn).wait()
        defer { _ = try? Planet.revert(on: conn).wait() }
        
        _ = try Planet(name: "Jupiter").save(on: conn).wait()
        _ = try Planet(name: "Earth").save(on: conn).wait()
        _ = try Planet(name: "Mars").save(on: conn).wait()
        
        let unordered = try Planet.query(on: conn).all().wait()
        let ordered = try Planet.query(on: conn).sort(\.name).all().wait()
        XCTAssertNotEqual(unordered, ordered)
    }
    
    func testCustomFilter() throws {
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }
        try Planet.prepare(on: conn).wait()
        defer { _ = try? Planet.revert(on: conn).wait() }
        
        _ = try Planet(name: "Jupiter").save(on: conn).wait()
        _ = try Planet(name: "Earth").save(on: conn).wait()
        _ = try Planet(name: "Mars").save(on: conn).wait()

        let earth = try Planet.query(on: conn).filter(\.name, .ilike, "earth").first().wait()
        XCTAssertEqual(earth?.name, "Earth")
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
        ("testBugs", testBugs),
        ("testCodableSimple", testCodableSimple),
        ("testURL", testURL),
        ("testDocs_type", testDocs_type),
        ("testContains", testContains),
        ("testEmptySubset", testEmptySubset),
        ("testSort", testSort),
        ("testCustomFilter", testCustomFilter),
    ]
}

struct Planet: PostgreSQLModel, PostgreSQLMigration, Equatable {
    var id: Int?
    var name: String
    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension PostgreSQLColumnType {
    static var planetType: PostgreSQLColumnType {
        return .custom("PLANET_TYPE")
    }
}

struct Pet: Codable {
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

/// Adds a new field to `User`'s table.
struct AddUsernameToUser: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(User.self, on: conn) { builder in
            builder.field(for: \.name)
        }
    }

    static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.update(User.self, on: conn) { builder in
            builder.deleteField(for: \.name)
        }
    }
}
