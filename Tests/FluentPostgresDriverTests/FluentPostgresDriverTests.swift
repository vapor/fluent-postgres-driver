import Logging
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import XCTest
import PostgresKit
import SQLKit

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line,
    _ callback: (any Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTAssertThrowsError({}(), message(), file: file, line: line, callback)
    } catch {
        XCTAssertThrowsError(try { throw error }(), message(), file: file, line: line, callback)
    }
}

func XCTAssertNoThrowAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTAssertNoThrow(try { throw error }(), message(), file: file, line: line)
    }
}

final class FluentPostgresDriverTests: XCTestCase {
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

    func testDatabaseError() async throws {
        let sql1 = (self.db as! any SQLDatabase)
        await XCTAssertThrowsErrorAsync(try await sql1.raw("asdf").run()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isSyntaxError ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConstraintFailure ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConnectionClosed ?? true, "\(String(reflecting: $0))")
        }
        
        let sql2 = (self.dbs.database(.a, logger: .init(label: "test.fluent.a"), on: self.eventLoopGroup.any())!) as! any SQLDatabase
        try await sql2.drop(table: "foo").ifExists().run()
        try await sql2.create(table: "foo").column("name", type: .text, .unique).run()
        try await sql2.insert(into: "foo").columns("name").values("bar").run()
        await XCTAssertThrowsErrorAsync(try await sql2.insert(into: "foo").columns("name").values("bar").run()) {
            XCTAssertTrue(($0 as? any DatabaseError)?.isConstraintFailure ?? false, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isSyntaxError ?? true, "\(String(reflecting: $0))")
            XCTAssertFalse(($0 as? any DatabaseError)?.isConnectionClosed ?? true, "\(String(reflecting: $0))")
        }
        
        // Disabled until we figure out why it hangs instead of throwing an error.
        //let postgres = (self.dbs.database(.a, logger: .init(label: "test.fluent.a"), on: self.eventLoopGroup.any())!) as! any PostgresDatabase
        //await XCTAssertThrowsErrorAsync(try await postgres.withConnection { conn in
        //    conn.close().flatMap {
        //        conn.sql().insert(into: "foo").columns("name").values("bar").run()
        //    }
        //}.get()) {
        //    XCTAssertTrue(($0 as? any DatabaseError)?.isConnectionClosed ?? false, "\(String(reflecting: $0))")
        //    XCTAssertFalse(($0 as? any DatabaseError)?.isSyntaxError ?? true, "\(String(reflecting: $0))")
        //    XCTAssertFalse(($0 as? any DatabaseError)?.isConstraintFailure ?? true, "\(String(reflecting: $0))")
        //}
    }
    
    func testBlob() async throws {
        struct CreateFoo: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("foos")
                    .field("id", .int, .identifier(auto: true))
                    .field("data", .data, .required)
                    .create()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("foos").delete()
            }
        }

        try await CreateFoo().prepare(on: self.db)
        try await CreateFoo().revert(on: self.db)
    }

    func testSaveModelWithBool() async throws {
        final class Organization: Model, @unchecked Sendable {
            static let schema = "orgs"

            @ID(custom: "id", generatedBy: .database) var id: Int?
            @Field(key: "disabled") var disabled: Bool

            init() {}
        }

        struct CreateOrganization: AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("orgs")
                    .field("id", .int, .identifier(auto: true))
                    .field("disabled", .bool, .required)
                    .create()
            }

            func revert(on database: any Database) async throws {
                try await database.schema("orgs").delete()
            }
        }

        try await CreateOrganization().prepare(on: self.db)
        do {
            let new = Organization()
            new.disabled = false
            try await new.save(on: self.db)
        } catch {
            try? await CreateOrganization().revert(on: self.db)
            throw error
        }
        try await CreateOrganization().revert(on: self.db)
    }

    func testCustomJSON() async throws {
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

        try await EventMigration().prepare(on: db)
        do {
            let date = Date()
            let event = Event()
            event.id = 1
            event.metadata = Metadata(createdAt: date)
            try await event.save(on: db)

            let rows = try await EventStringlyTyped.query(on: db).filter(\.$id == 1).all()
            let expected = ISO8601DateFormatter().string(from: date)
            XCTAssertEqual(rows[0].metadata["createdAt"], expected)
        } catch {
            try? await EventMigration().revert(on: db)
            throw error
        }
        try await EventMigration().revert(on: db)
    }

    func testEnumAddingMultipleCases() async throws {
        try await EnumMigration().prepare(on: self.db)
        do {
            try await EventWithFooMigration().prepare(on: self.db)
            do {
                let event = EventWithFoo()
                event.foobar = .foo
                try await event.save(on: self.db)

                await XCTAssertNoThrowAsync(try await EnumAddMultipleCasesMigration().prepare(on: self.db))

                event.foobar = .baz
                await XCTAssertNoThrowAsync(try await event.update(on: self.db))
                event.foobar = .qux
                await XCTAssertNoThrowAsync(try await event.update(on: self.db))

                await XCTAssertNoThrowAsync(try await EnumAddMultipleCasesMigration().revert(on: self.db))
            } catch {
                try? await EventWithFooMigration().revert(on: self.db)
                throw error
            }
        } catch {
            try? await EnumMigration().revert(on: self.db)
            throw error
        }
    }
    
    func testEncodingArrayOfModels() async throws {
        final class Elem: Model, ExpressibleByIntegerLiteral, @unchecked Sendable {
            static let schema = ""
            @ID(custom: .id) var id: Int?
            init() {}; init(integerLiteral l: Int) { self.id = l }
        }
        final class Seq: Model, ExpressibleByNilLiteral, ExpressibleByArrayLiteral, @unchecked Sendable {
            static let schema = "seqs"
            @ID(custom: .id) var id: Int?; @OptionalField(key: "list") var list: [Elem]?
            init() {}; init(nilLiteral: ()) { self.list = nil }; init(arrayLiteral el: Elem...) { self.list = el }
        }
        do {
            try await self.db.schema(Seq.schema).field(.id, .int, .identifier(auto: true)).field("list", .sql(embed: "JSONB[]")).create()
            
            let s1: Seq = [1, 2], s2: Seq = nil; try [s1, s2].forEach { try $0.create(on: self.db).wait() }
            
            // Make sure it went into the DB as "array of jsonb" rather than as "array of one jsonb containing array" or such.
            let raws = try await (self.db as! any SQLDatabase).raw("SELECT array_to_json(list)::text t FROM seqs").all().map { try $0.decode(column: "t", as: String?.self) }
            XCTAssertEqual(raws, [#"[{"id": 1},{"id": 2}]"#, nil])
            
            // Make sure it round-trips through Fluent.
            let seqs = try await Seq.query(on: self.db).all()
            
            XCTAssertEqual(seqs.count, 2)
            XCTAssertEqual(seqs.dropFirst(0).first?.id, s1.id)
            XCTAssertEqual(seqs.dropFirst(0).first?.list?.map(\.id), s1.list?.map(\.id))
            XCTAssertEqual(seqs.dropFirst(1).first?.id, s2.id)
            XCTAssertEqual(seqs.dropFirst(1).first?.list?.map(\.id), s2.list?.map(\.id))
        } catch let error {
            XCTFail("caught error: \(String(reflecting: error))")
        }
        try await db.schema(Seq.schema).delete()
    }

    
    var benchmarker: FluentBenchmarker { .init(databases: self.dbs) }
    var eventLoopGroup: any EventLoopGroup { MultiThreadedEventLoopGroup.singleton }
    var threadPool: NIOThreadPool { NIOThreadPool.singleton }
    var dbs: Databases!
    var db: (any Database)!
    var postgres: any PostgresDatabase { self.db as! any PostgresDatabase }
    
    override func setUp() async throws {
        try await super.setUp()
        
        XCTAssert(isLoggingConfigured)
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)
        self.dbs.use(.testPostgres(subconfig: "B"), as: .b)

        let a = self.dbs.database(.a, logger: .init(label: "test.fluent.a"), on: self.eventLoopGroup.any())
        _ = try await (a as! any PostgresDatabase).query("drop schema public cascade").get()
        _ = try await (a as! any PostgresDatabase).query("create schema public").get()

        let b = self.dbs.database(.b, logger: .init(label: "test.fluent.b"), on: self.eventLoopGroup.any())
        _ = try await (b as! any PostgresDatabase).query("drop schema public cascade").get()
        _ = try await (b as! any PostgresDatabase).query("create schema public").get()

        self.db = a
     }

    override func tearDown() async throws {
        await self.dbs.shutdownAsync()
        try await super.tearDown()
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

struct Metadata: Codable {
    let createdAt: Date
}

final class Event: Model, @unchecked Sendable {
    static let schema = "events"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "metadata")
    var metadata: Metadata
}

final class EventStringlyTyped: Model, @unchecked Sendable {
    static let schema = "events"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "metadata")
    var metadata: [String: String]
}

struct EventMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Event.schema)
            .field("id", .int, .identifier(auto: true))
            .field("metadata", .json, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Event.schema).delete()
    }
}

final class EventWithFoo: Model, @unchecked Sendable {
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

struct EventWithFooMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let foobar = try await database.enum(Foobar.schema).read()
        try await database.schema(EventWithFoo.schema)
            .id()
            .field("foo", foobar, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(EventWithFoo.schema).delete()
    }
}

struct EnumMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        _ = try await database.enum(Foobar.schema)
            .case("foo")
            .case("bar")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.enum(Foobar.schema).delete()
    }
}

struct EnumAddMultipleCasesMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        _ = try await database.enum(Foobar.schema)
            .case("baz")
            .case("qux")
            .update()
    }

    func revert(on database: any Database) async throws {
        _ = try await database.enum(Foobar.schema)
            .deleteCase("baz")
            .deleteCase("qux")
            .update()
    }
}

func env(_ name: String) -> String? {
    ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { .init(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
