import Logging
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import XCTest
import PostgresKit

final class FluentPostgresTransactionControlTests: XCTestCase {
    func testRollback() throws {
        do {
            try self.db.withConnection { db -> EventLoopFuture<Void> in
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
            }.wait()
            XCTFail("Expected error but none was thrown")
        } catch let error as PSQLError where error.code == .server && error.serverInfo?[.sqlState] == "23505" {
            // ignore
        } catch {
            XCTFail("Expected SQL state 23505 but got \(error)")
        }

        let count2 = try Todo.query(on: self.db).count().wait()
        XCTAssertEqual(count2, 0)
    }
    
    var eventLoopGroup: (any EventLoopGroup)!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: (any Database)!
    
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
        func prepare(on database: any Database) -> EventLoopFuture<Void> {
            database.schema("todos")
                .id()
                .field("title", .string, .required)
                .unique(on: "title")
                .create()
        }

        func revert(on database: any Database) -> EventLoopFuture<Void> {
            database.schema("todos").delete()
        }
    }
}
