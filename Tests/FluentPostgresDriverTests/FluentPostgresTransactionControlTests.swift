import Logging
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import XCTest
import PostgresKit

final class FluentPostgresTransactionControlTests: XCTestCase {
    func testRollback() async throws {
        do {
            try await self.db.withConnection { db -> EventLoopFuture<Void> in
                (db as! any TransactionControlDatabase).beginTransaction().flatMap { () -> EventLoopFuture<Void> in
                    let todo1 = Todo(title: "Test")
                    return todo1.save(on: db)
                }.flatMap { () -> EventLoopFuture<Void> in
                    let duplicate = Todo(title: "Test")
                    return duplicate.create(on: db)
                        .flatMap {
                            (db as! any TransactionControlDatabase).commitTransaction()
                        }.flatMapError { (e: Error) -> EventLoopFuture<Void> in
                            return (db as! any TransactionControlDatabase).rollbackTransaction()
                                .flatMap { db.eventLoop.makeFailedFuture(e) }
                        }
                }
            }.get()
            XCTFail("Expected error but none was thrown")
        } catch let error where String(reflecting: error).contains("sqlState: 23505") {
            // ignore
        } catch {
            XCTFail("Expected SQL state 23505 but got \(String(reflecting: error))")
        }

        let count2 = try await Todo.query(on: self.db).count()
        XCTAssertEqual(count2, 0)
    }
    
    var eventLoopGroup: any EventLoopGroup { MultiThreadedEventLoopGroup.singleton }
    var threadPool: NIOThreadPool { NIOThreadPool.singleton }
    var dbs: Databases!
    var db: (any Database)!
    
    override func setUp() async throws {
        try await super.setUp()
        
        XCTAssert(isLoggingConfigured)
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)

        self.db = self.dbs.database(.a, logger: Logger(label: "test.fluent.a"), on: self.eventLoopGroup.any())
        _ = try await (self.db as! any PostgresDatabase).query("drop schema public cascade").get()
        _ = try await (self.db as! any PostgresDatabase).query("create schema public").get()
        
        try await CreateTodo().prepare(on: self.db)
    }

    override func tearDown() async throws {
        try await CreateTodo().revert(on: self.db)
        self.dbs.shutdown()
        try await super.tearDown()
    }
    
    final class Todo: Model, @unchecked Sendable {
        static let schema = "todos"

        @ID
        var id: UUID?

        @Field(key: "title")
        var title: String

        init() {}
        init(title: String) { self.title = title; id = nil }
    }
    
    struct CreateTodo: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("todos")
                .id()
                .field("title", .string, .required)
                .unique(on: "title")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("todos").delete()
        }
    }
}
