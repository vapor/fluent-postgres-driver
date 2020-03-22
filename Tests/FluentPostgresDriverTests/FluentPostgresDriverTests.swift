import Logging
import FluentBenchmark
import FluentPostgresDriver
import XCTest

final class FluentPostgresDriverTests: XCTestCase {
    func testAll() throws { try self.benchmarker.testAll() }
    func testAggregate() throws { try self.benchmarker.testAggregate() }
    func testArray() throws { try self.benchmarker.testArray() }
    func testBatch() throws { try self.benchmarker.testBatch() }
    func testChildren() throws { try self.benchmarker.testChildren() }
    func testChunk() throws { try self.benchmarker.testChunk() }
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
    func testSet() throws { try self.benchmarker.testSet() }
    func testSiblings() throws { try self.benchmarker.testSiblings() }
    func testSoftDelete() throws { try self.benchmarker.testSoftDelete() }
    func testSort() throws { try self.benchmarker.testSort() }
    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
    func testTransaction() throws { try self.benchmarker.testTransaction() }
    func testUnique() throws { try self.benchmarker.testUnique() }

    func testDatabaseError() throws {
        let sql = (self.db as! SQLDatabase)
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
        final class Foo: Model {
            static let schema = "foos"

            @ID(key: "id")
            var id: Int?

            @Field(key: "data")
            var data: [UInt8]

            init() { }
        }

        struct CreateFoo: Migration {
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos")
                    .field("id", .int, .identifier(auto: true))
                    .field("data", .data, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("foos").delete()
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
            func prepare(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("orgs")
                    .field("id", .int, .identifier(auto: true))
                    .field("disabled", .bool, .required)
                    .create()
            }

            func revert(on database: Database) -> EventLoopFuture<Void> {
                return database.schema("orgs").delete()
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

        let configuration = PostgresConfiguration(
            hostname: hostname,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database",
            encoder: PostgresDataEncoder(json: jsonEncoder),
            decoder: PostgresDataDecoder(json: jsonDecoder)
        )
        self.dbs.use(.postgres(configuration: configuration), as: .iso8601)
        let db = self.dbs.database(
            .iso8601,
            logger: .init(label: "test"),
            on: self.eventLoopGroup.next()
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

    
    var benchmarker: FluentBenchmarker {
        return .init(databases: self.dbs)
    }
    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: Database {
        self.benchmarker.database
    }
    var postgres: PostgresDatabase {
        self.db as! PostgresDatabase
    }
    
    override func setUp() {
        let configuration = PostgresConfiguration(
            hostname: hostname,
            username: "vapor_username",
            password: "vapor_password",
            database: "vapor_database"
        )
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)
        self.dbs.use(.postgres(configuration: configuration), as: .psql)

        // reset the database
        _ = try! self.postgres.query("drop schema public cascade").wait()
        _ = try! self.postgres.query("create schema public").wait()
    }

    override func tearDown() {
        self.dbs.shutdown()
        try! self.threadPool.syncShutdownGracefully()
        try! self.eventLoopGroup.syncShutdownGracefully()
    }
}

extension DatabaseID {
    static var iso8601: Self {
        .init(string: "iso8601")
    }
}

var hostname: String {
    getenv("POSTGRES_HOSTNAME").flatMap {
        String(cString: $0)
    } ?? "localhost"
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
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Event.schema)
            .field("id", .int, .identifier(auto: true))
            .field("metadata", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Event.schema).delete()
    }
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
