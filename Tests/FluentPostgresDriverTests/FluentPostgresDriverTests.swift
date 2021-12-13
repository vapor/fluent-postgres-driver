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

        self.dbs.use(.testPostgres(subconfig: "A",
            encoder: PostgresDataEncoder(json: jsonEncoder),
            decoder: PostgresDataDecoder(json: jsonDecoder)
        ), as: .iso8601)
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
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.threadPool = NIOThreadPool(numberOfThreads: System.coreCount)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)
        self.dbs.use(.testPostgres(subconfig: "B"), as: .b)

        let a = self.dbs.database(.a, logger: Logger(label: "test.fluent.a"), on: self.eventLoopGroup.next())
        _ = try (a as! PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (a as! PostgresDatabase).query("create schema public").wait()

        let b = self.dbs.database(.b, logger: Logger(label: "test.fluent.b"), on: self.eventLoopGroup.next())
        _ = try (b as! PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (b as! PostgresDatabase).query("create schema public").wait()
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
        encoder: PostgresDataEncoder = .init(), decoder: PostgresDataDecoder = .init()
    ) -> DatabaseConfigurationFactory {
        let baseSubconfig = PostgresConfiguration(
            hostname: env("POSTGRES_HOSTNAME_\(subconfig)") ?? "localhost",
            port: env("POSTGRES_PORT_\(subconfig)").flatMap(Int.init) ?? PostgresConfiguration.ianaPortNumber,
            username: env("POSTGRES_USER_\(subconfig)") ?? "vapor_username",
            password: env("POSTGRES_PASSWORD_\(subconfig)") ?? "vapor_password",
            database: env("POSTGRES_DB_\(subconfig)") ?? "vapor_database"
        )
        
        return .postgres(configuration: baseSubconfig, connectionPoolTimeout: .seconds(30), encoder: encoder, decoder: decoder)
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
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .debug
        return handler
    }
    return true
}()
