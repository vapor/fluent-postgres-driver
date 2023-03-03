import Logging
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import XCTest
import PostgresKit

final class FluentPostgresTransactionControlTests: XCTestCase {
    
    func testTransactionControl() throws {
        try (self.db as! TransactionControlDatabase).beginTransaction().wait()
        
        let todo1 = Todo(title: "Test")
        let todo2 = Todo(title: "Test2")
        try todo1.save(on: self.db).wait()
        try todo2.save(on: self.db).wait()
        
        try (self.db as! TransactionControlDatabase).commitTransaction().wait()
        
        let count = try Todo.query(on: self.db).count().wait()
        XCTAssertEqual(count, 2)
    }
    
    func testRollback() throws {
        try (self.db as! TransactionControlDatabase).beginTransaction().wait()
        
        let todo1 = Todo(title: "Test")
        
        try todo1.save(on: self.db).wait()
        
        let duplicate = Todo(title: "Test")
        var errorCaught = false
        
        do {
            try duplicate.create(on: self.db).wait()
        } catch {
            errorCaught = true
            try (self.db as! TransactionControlDatabase).rollbackTransaction().wait()
        }
        
        if !errorCaught {
            try (self.db as! TransactionControlDatabase).commitTransaction().wait()
        }
        
        XCTAssertTrue(errorCaught)
        let count2 = try Todo.query(on: self.db).count().wait()
        XCTAssertEqual(count2, 0)
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
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: Swift.min(System.coreCount, 2))
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)

        self.dbs.use(.testPostgres(subconfig: "A"), as: .a)
        self.dbs.use(.testPostgres(subconfig: "B"), as: .b)

        let a = self.dbs.database(.a, logger: Logger(label: "test.fluent.a"), on: self.eventLoopGroup.next())
        _ = try (a as! PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (a as! PostgresDatabase).query("create schema public").wait()

        let b = self.dbs.database(.b, logger: Logger(label: "test.fluent.b"), on: self.eventLoopGroup.next())
        _ = try (b as! PostgresDatabase).query("drop schema public cascade").wait()
        _ = try (b as! PostgresDatabase).query("create schema public").wait()
        
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
