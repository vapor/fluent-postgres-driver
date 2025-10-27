import FluentBenchmark
import FluentKit
import FluentPostgresDriver
import FluentSQL
import Logging
import PostgresKit
import SQLKit
import Testing
import XCTest

func withDbs(_ closure: @escaping @Sendable (_ dbs: Databases, _ db: any Database) async throws -> Void) async throws {
    let databases = Databases(threadPool: .singleton, on: MultiThreadedEventLoopGroup.singleton)

    databases.use(.testPostgres(subconfig: "A"), as: .a)
    databases.use(.testPostgres(subconfig: "B"), as: .b)

    do {
        let a = databases.database(.a, logger: .init(label: "test.fluent.a"), on: databases.eventLoopGroup.any())!
        _ = try await (a as! any SQLDatabase).raw("drop schema if exists public cascade").run()
        _ = try await (a as! any SQLDatabase).raw("create schema public").run()

        let b = databases.database(.b, logger: .init(label: "test.fluent.b"), on: databases.eventLoopGroup.any())!
        _ = try await (b as! any SQLDatabase).raw("drop schema if exists public cascade").run()
        _ = try await (b as! any SQLDatabase).raw("create schema public").run()

        try await closure(databases, a)
        await databases.shutdownAsync()
    } catch {
        print(String(reflecting: error))
        await databases.shutdownAsync()
        throw error
    }
}

final class FluentBenchmarksTests: XCTestCase {
    var benchmarker: FluentBenchmarker { .init(databases: self.dbs) }
    var dbs: Databases!

    override func setUp() async throws {
        try await super.setUp()

        XCTAssert(isLoggingConfigured)
        self.dbs = Databases(threadPool: .singleton, on: MultiThreadedEventLoopGroup.singleton)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)
        self.dbs.use(.testPostgres(subconfig: "B"), as: .b)

        let a = self.dbs.database(.a, logger: .init(label: "test.fluent.a"), on: self.dbs.eventLoopGroup.any())
        _ = try await (a as! any PostgresDatabase).query("drop schema public cascade").get()
        _ = try await (a as! any PostgresDatabase).query("create schema public").get()

        let b = self.dbs.database(.b, logger: .init(label: "test.fluent.b"), on: self.dbs.eventLoopGroup.any())
        _ = try await (b as! any PostgresDatabase).query("drop schema public cascade").get()
        _ = try await (b as! any PostgresDatabase).query("create schema public").get()
    }

    override func tearDown() async throws {
        await self.dbs.shutdownAsync()
        try await super.tearDown()
    }

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
}

@Suite(.serialized)
struct AllSuites {}

extension AllSuites {
@Suite
struct FluentPostgresDriverTests {
    init() {
        #expect(isLoggingConfigured)
    }

    #if !compiler(<6.1) // #expect(throws:) doesn't return the Error until 6.1
    @Test
    func databaseError() async throws {
        try await withDbs { dbs, db in
            let sql1 = (db as! any SQLDatabase)
            let error1 = await #expect(throws: (any Error).self) { try await sql1.raw("asdf").run() }
            #expect((error1 as? any DatabaseError)?.isSyntaxError ?? false, "\(String(reflecting: error1))")
            #expect(!((error1 as? any DatabaseError)?.isConstraintFailure ?? true), "\(String(reflecting: error1))")
            #expect(!((error1 as? any DatabaseError)?.isConnectionClosed ?? true), "\(String(reflecting: error1))")

            let sql2 = (dbs.database(.a, logger: .init(label: "test.fluent.a"), on: dbs.eventLoopGroup.any())!) as! any SQLDatabase
            try await sql2.drop(table: "foo").ifExists().run()
            try await sql2.create(table: "foo").column("name", type: .text, .unique).run()
            try await sql2.insert(into: "foo").columns("name").values("bar").run()
            let error2 = await #expect(throws: (any Error).self) { try await sql2.insert(into: "foo").columns("name").values("bar").run() }
            #expect((error2 as? any DatabaseError)?.isSyntaxError ?? false, "\(String(reflecting: error2))")
            #expect(!((error2 as? any DatabaseError)?.isConstraintFailure ?? true), "\(String(reflecting: error2))")
            #expect(!((error2 as? any DatabaseError)?.isConnectionClosed ?? true), "\(String(reflecting: error2))")
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
    #endif

    @Test
    func blob() async throws {
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

        try await withDbs { _, db in
            try await CreateFoo().prepare(on: db)
            try await CreateFoo().revert(on: db)
        }
    }

    @Test
    func saveModelWithBool() async throws {
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

        try await withDbs { _, db in
            try await CreateOrganization().prepare(on: db)
            do {
                let new = Organization()
                new.disabled = false
                try await new.save(on: db)
            } catch {
                try? await CreateOrganization().revert(on: db)
                throw error
            }
            try await CreateOrganization().revert(on: db)
        }
    }

    @Test
    func customJSON() async throws {
        try await withDbs { dbs, _ in
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601

            dbs.use(
                .testPostgres(
                    subconfig: "A",
                    encodingContext: .init(jsonEncoder: jsonEncoder),
                    decodingContext: .init(jsonDecoder: jsonDecoder)
                ),
                as: .iso8601
            )
            let db = dbs.database(
                .iso8601,
                logger: .init(label: "test"),
                on: dbs.eventLoopGroup.any()
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
                #expect(rows[0].metadata["createdAt"] == expected)
            } catch {
                try? await EventMigration().revert(on: db)
                throw error
            }
            try await EventMigration().revert(on: db)
        }
    }

    @Test
    func enumAddingMultipleCases() async throws {
        try await withDbs { _, db in
            try await EnumMigration().prepare(on: db)
            do {
                try await EventWithFooMigration().prepare(on: db)
                do {
                    let event = EventWithFoo()
                    event.foobar = .foo
                    try await event.save(on: db)

                    await #expect(throws: Never.self) { try await EnumAddMultipleCasesMigration().prepare(on: db) }

                    event.foobar = .baz
                    await #expect(throws: Never.self) { try await event.update(on: db) }
                    event.foobar = .qux
                    await #expect(throws: Never.self) { try await event.update(on: db) }

                    await #expect(throws: Never.self) { try await EnumAddMultipleCasesMigration().revert(on: db) }
                } catch {
                    try? await EventWithFooMigration().revert(on: db)
                    throw error
                }
            } catch {
                try? await EnumMigration().revert(on: db)
                throw error
            }
        }
    }

    @Test
    func encodingArrayOfModels() async throws {
        final class Elem: Model, ExpressibleByIntegerLiteral, @unchecked Sendable {
            static let schema = ""
            @ID(custom: .id) var id: Int?
            init() {}
            init(integerLiteral l: Int) { self.id = l }
        }
        final class Seq: Model, ExpressibleByNilLiteral, ExpressibleByArrayLiteral, @unchecked Sendable {
            static let schema = "seqs"
            @ID(custom: .id) var id: Int?
            @OptionalField(key: "list") var list: [Elem]?
            init() {}
            init(nilLiteral: ()) { self.list = nil }
            init(arrayLiteral el: Elem...) { self.list = el }
        }
        try await withDbs { _, db in
            do {
                try await db.schema(Seq.schema).field(.id, .int, .identifier(auto: true)).field("list", .sql(embed: "JSONB[]")).create()

                let s1: Seq = [1, 2]
                let s2: Seq = nil
                try await s1.create(on: db)
                try await s2.create(on: db)

                // Make sure it went into the DB as "array of jsonb" rather than as "array of one jsonb containing array" or such.
                let raws = try await (db as! any SQLDatabase).raw("SELECT array_to_json(list)::text t FROM seqs").all().map {
                    try $0.decode(column: "t", as: String?.self)
                }
                #expect(raws == [#"[{"id": 1},{"id": 2}]"#, nil])

                // Make sure it round-trips through Fluent.
                let seqs = try await Seq.query(on: db).all()

                #expect(seqs.count == 2)
                #expect(seqs.dropFirst(0).first?.id == s1.id)
                #expect(seqs.dropFirst(0).first?.list?.map(\.id) == s1.list?.map(\.id))
                #expect(seqs.dropFirst(1).first?.id == s2.id)
                #expect(seqs.dropFirst(1).first?.list?.map(\.id) == s2.list?.map(\.id))
            } catch let error {
                Issue.record("caught error: \(String(reflecting: error))")
            }
            try await db.schema(Seq.schema).delete()
        }
    }
}
}

extension DatabaseConfigurationFactory {
    static func testPostgres(
        subconfig: String,
        encodingContext: PostgresEncodingContext<some PostgresJSONEncoder> = .default,
        decodingContext: PostgresDecodingContext<some PostgresJSONDecoder> = .default
    ) -> Self {
        let baseSubconfig = SQLPostgresConfiguration(
            hostname: ProcessInfo.processInfo.environment["POSTGRES_HOSTNAME_\(subconfig)"] ?? "localhost",
            port: ProcessInfo.processInfo.environment["POSTGRES_PORT_\(subconfig)"].flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: ProcessInfo.processInfo.environment["POSTGRES_USER_\(subconfig)"] ?? "test_username",
            password: ProcessInfo.processInfo.environment["POSTGRES_PASSWORD_\(subconfig)"] ?? "test_password",
            database: ProcessInfo.processInfo.environment["POSTGRES_DB_\(subconfig)"] ?? "test_database",
            tls: try! .prefer(.init(configuration: .makeClientConfiguration()))
        )

        return .postgres(
            configuration: baseSubconfig,
            connectionPoolTimeout: .seconds(30),
            pruneInterval: .seconds(30),
            maxIdleTimeBeforePruning: .seconds(60),
            encodingContext: encodingContext,
            decodingContext: decodingContext
        )
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

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { QuickLogHandler(label: $0, level: ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap { .init(rawValue: $0) } ?? .info) }
    return true
}()

struct QuickLogHandler: LogHandler {
    private let label: String
    var logLevel = Logger.Level.info, metadataProvider = LoggingSystem.metadataProvider, metadata = Logger.Metadata()
    subscript(metadataKey key: String) -> Logger.Metadata.Value? { get { self.metadata[key] } set { self.metadata[key] = newValue } }
    init(label: String, level: Logger.Level) { (self.label, self.logLevel) = (label, level) }
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        print("\(self.timestamp()) \(level) \(self.label) :\(self.prettify(metadata ?? [:]).map { " \($0)" } ?? "") [\(source)] \(message)")
    }
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        self.metadata.merging(self.metadataProvider?.get() ?? [:]) { $1 }.merging(metadata) { $1 }.sorted { $0.0 < $1.0 }.map { "\($0)=\($1.mvDesc)" }.joined(separator: " ")
    }
    private func timestamp() -> String { .init(unsafeUninitializedCapacity: 255) { buffer in
        var timestamp = time(nil)
        return localtime(&timestamp).map { strftime(buffer.baseAddress!, buffer.count, "%Y-%m-%dT%H:%M:%S%z", $0) } ?? buffer.initialize(fromContentsOf: "<unknown>".utf8)
    } }
}
extension Logger.MetadataValue {
    var mvDesc: String { switch self {
        case .dictionary(let dict): "[\(dict.mapValues(\.mvDesc).lazy.sorted { $0.0 < $1.0 }.map { "\($0): \($1)" }.joined(separator: ", "))]"
        case .array(let list): "[\(list.map(\.mvDesc).joined(separator: ", "))]"
        case .string(let str): #""\#(str)""#
        case .stringConvertible(let repr): switch repr {
            case let repr as Bool: "\(repr)"
            case let repr as any FixedWidthInteger: "\(repr)"
            case let repr as any BinaryFloatingPoint: "\(repr)"
            default: #""\#(String(describing: repr))""#
        }
    } }
}
