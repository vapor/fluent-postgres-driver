import Logging
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import XCTest
import PostgresKit

final class FluentPostgresDriverTests: XCTestCase {
    //func testAll() throws { try self.benchmarker.testAll() }
    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
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

    func testDatabaseError() throws {
        let sql = (self.db as! any SQLDatabase)
        do {
            try sql.raw("asd").run().wait()
        } catch let error as DatabaseError where error.isSyntaxError {
            // PASS
        } catch {
            XCTFail("\(error)")
        }
        do {
            try sql.raw("CREATE TABLE foo (name TEXT UNIQUE)").run().wait()
            try sql.raw("INSERT INTO foo (name) VALUES ('bar')").run().wait()
            try sql.raw("INSERT INTO foo (name) VALUES ('bar')").run().wait()
        } catch let error as DatabaseError where error.isConstraintFailure {
            // pass
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testBlob() throws {
        struct CreateFoo: Migration {
            func prepare(on database: any Database) -> EventLoopFuture<Void> {
                database.schema("foos")
                    .field("id", .int, .identifier(auto: true))
                    .field("data", .data, .required)
                    .create()
            }

            func revert(on database: any Database) -> EventLoopFuture<Void> {
                database.schema("foos").delete()
            }
        }

        try CreateFoo().prepare(on: self.db).wait()
        try CreateFoo().revert(on: self.db).wait()
    }

    func testSaveModelWithBool() throws {
        final class Organization: Model {
            static let schema = "orgs"

            @ID(custom: "id", generatedBy: .database)
            var id: Int?

            @Field(key: "disabled")
            var disabled: Bool

            init() { }
        }

        struct CreateOrganization: Migration {
            func prepare(on database: any Database) -> EventLoopFuture<Void> {
                database.schema("orgs")
                    .field("id", .int, .identifier(auto: true))
                    .field("disabled", .bool, .required)
                    .create()
            }

            func revert(on database: any Database) -> EventLoopFuture<Void> {
                database.schema("orgs").delete()
            }
        }

        try CreateOrganization().prepare(on: self.db).wait()
        defer {
            try! CreateOrganization().revert(on: self.db).wait()
        }

        let new = Organization()
        new.disabled = false
        try new.save(on: self.db).wait()
    }

    func testCustomJSON() throws {
        try EventMigration().prepare(on: self.db).wait()
        defer { try! EventMigration().revert(on: self.db).wait() }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        self.dbs.use(.testPostgres(subconfig: "A",
            encodingContext: .init(jsonEncoder: jsonEncoder),
            decodingContext: .init(jsonDecoder: jsonDecoder)
        ), as: .iso8601)
        let db = self.dbs.database(
            .iso8601,
            logger: .init(label: "test"),
            on: self.eventLoopGroup.any()
        )!

        let date = Date()
        let event = Event()
        event.id = 1
        event.metadata = Metadata(createdAt: date)
        try event.save(on: db).wait()

        let rows = try EventStringlyTyped.query(on: db).filter(\.$id == 1).all().wait()
        let expected = ISO8601DateFormatter().string(from: date)
        XCTAssertEqual(rows[0].metadata["createdAt"], expected)
    }

    func testEnumAddingMultipleCases() throws {
        try EnumMigration().prepare(on: self.db).wait()
        try EventWithFooMigration().prepare(on: self.db).wait()

        let event = EventWithFoo()
        event.foobar = .foo
        try event.save(on: self.db).wait()

        XCTAssertNoThrow(try EnumAddMultipleCasesMigration().prepare(on: self.db).wait())

        event.foobar = .baz
        XCTAssertNoThrow(try event.update(on: self.db).wait())
        event.foobar = .qux
        XCTAssertNoThrow(try event.update(on: self.db).wait())

        XCTAssertNoThrow(try EnumAddMultipleCasesMigration().revert(on: self.db).wait())
        try! EventWithFooMigration().revert(on: self.db).wait()
        try! EnumMigration().revert(on: self.db).wait()
    }

    
    var benchmarker: FluentBenchmarker {
        return .init(databases: self.dbs)
    }
    var eventLoopGroup: (any EventLoopGroup)!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: any Database {
        self.benchmarker.database
    }
    var postgres: any PostgresDatabase {
        self.db as! any PostgresDatabase
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: Swift.min(System.coreCount, 2))
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)
        self.dbs.use(.testPostgres(subconfig: "B"), as: .b)

        let a = self.dbs.database(.a, logger: Logger(label: "test.fluent.a"), on: self.eventLoopGroup.any())
        _ = try (a as! any PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (a as! any PostgresDatabase).query("create schema public").wait()

        let b = self.dbs.database(.b, logger: Logger(label: "test.fluent.b"), on: self.eventLoopGroup.any())
        _ = try (b as! any PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (b as! any PostgresDatabase).query("create schema public").wait()
    }

    override func tearDownWithError() throws {
        self.dbs.shutdown()
        try self.threadPool.syncShutdownGracefully()
        try self.eventLoopGroup.syncShutdownGracefully()
        try super.tearDownWithError()
    }
}

extension DatabaseConfigurationFactory {
    static func testPostgres(
        subconfig: String,
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default
    ) -> DatabaseConfigurationFactory {
        let baseSubconfig = SQLPostgresConfiguration(
            hostname: env("POSTGRES_HOSTNAME_\(subconfig)") ?? "localhost",
            port: env("POSTGRES_PORT_\(subconfig)").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: env("POSTGRES_USER_\(subconfig)") ?? "test_username",
            password: env("POSTGRES_PASSWORD_\(subconfig)") ?? "test_password",
            database: env("POSTGRES_DB_\(subconfig)") ?? "test_database",
            tls: try! .prefer(.init(configuration: .makeClientConfiguration()))
        )
        
        return .postgres(configuration: baseSubconfig, connectionPoolTimeout: .seconds(30), encodingContext: encodingContext, decodingContext: decodingContext)
    }
}

extension DatabaseID {
    static let iso8601 = DatabaseID(string: "iso8601")
    static let a = DatabaseID(string: "a")
    static let b = DatabaseID(string: "b")
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

struct Metadata: Codable {
    let createdAt: Date
}

final class Event: Model {
    static let schema = "events"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "metadata")
    var metadata: Metadata
}

final class EventStringlyTyped: Model {
    static let schema = "events"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "metadata")
    var metadata: [String: String]
}

struct EventMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(Event.schema)
            .field("id", .int, .identifier(auto: true))
            .field("metadata", .json, .required)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(Event.schema).delete()
    }
}

final class EventWithFoo: Model {
    static let schema = "foobar_events"

    @ID
    var id: UUID?

    @Enum(key: "foo")
    var foobar: Foobar
}

enum Foobar: String, Codable {
    static let schema = "foobars"
    case foo
    case bar
    case baz
    case qux
}

struct EventWithFooMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.enum(Foobar.schema).read()
            .flatMap { foobar in
                database.schema(EventWithFoo.schema)
                    .id()
                    .field("foo", foobar, .required)
                    .create()
            }
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(EventWithFoo.schema).delete()
    }
}

struct EnumMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.enum(Foobar.schema)
            .case("foo")
            .case("bar")
            .create()
            .transform(to: ())
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.enum(Foobar.schema).delete()
    }
}

struct EnumAddMultipleCasesMigration: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.enum(Foobar.schema)
            .case("baz")
            .case("qux")
            .update()
            .transform(to: ())
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.enum(Foobar.schema)
            .deleteCase("baz")
            .deleteCase("qux")
            .update()
            .transform(to: ())
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
