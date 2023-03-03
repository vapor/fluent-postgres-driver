import Logging
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import XCTest
import PostgresKit

final class FluentPostgresTransactionControlTests: XCTestCase {
    
    func testRollback() throws {
        do {
            try self.db.withConnection { db in
                (db as! TransactionControlDatabase).beginTransaction().flatMap {
                    let todo1 = Todo(title: "Test")
                    return todo1.save(on: db)
                }.flatMap {
                    let duplicate = Todo(title: "Test")
                    return duplicate.create(on: db)
                        .flatMap {
                            (db as! TransactionControlDatabase).commitTransaction()
                        }.flatMapError { e in
                            return (db as! TransactionControlDatabase).rollbackTransaction()
                                .flatMap { db.eventLoop.makeFailedFuture(e) }
                        }
                }
            }.wait()
            XCTFail("Expected error but none was thrown")
        } catch PostgresError.server(let e) where e.fields[.sqlState] == "23505" {
            // ignore
        } catch {
            XCTFail("Expected SQL state 23505 but got \(error)")
        }

        let count2 = try Todo.query(on: self.db).count().wait()
        XCTAssertEqual(count2, 0)
    }
    
    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: Database!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: Swift.min(System.coreCount, 2))
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)

        self.db = self.dbs.database(.a, logger: Logger(label: "test.fluent.a"), on: self.eventLoopGroup.any())
        _ = try (self.db as! PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (self.db as! PostgresDatabase).query("create schema public").wait()
        
        try CreateTodo().prepare(on: self.db).wait()
    }

    override func tearDownWithError() throws {
        try CreateTodo().revert(on: self.db).wait()
        self.dbs.shutdown()
        try self.threadPool.syncShutdownGracefully()
        try self.eventLoopGroup.syncShutdownGracefully()
        try super.tearDownWithError()
    }
    
    final class Todo: Model {
        static let schema = "todos"

        @ID
        var id: UUID?

        @Field(key: "title")
        var title: String

        init() {}
        init(title: String) { self.title = title; id = nil }
    }
    
    struct CreateTodo: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("todos")
                .id()
                .field("title", .string, .required)
                .unique(on: "title")
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("todos").delete()
        }
    }
}
