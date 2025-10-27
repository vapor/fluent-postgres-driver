import FluentKit
import Testing

extension AllSuites {
@Suite
struct FluentPostgresTransactionControlTests {
    init() { #expect(isLoggingConfigured) }

    #if !compiler(<6.1) // #expect(throws:) doesn't return the Error until 6.1
    @Test
    func rollback() async throws {
        try await withDbs { _, db in try await db.withConnection { db in
            try await CreateTodo().prepare(on: db)
            do {
                try await (db as! any TransactionControlDatabase).beginTransaction().get()
                let error = await #expect(throws: (any Error).self) {
                    try await [Todo(title: "Test"), Todo(title: "Test")].create(on: db)
                    try await (db as! any TransactionControlDatabase).commitTransaction().get()
                }
                #expect(String(reflecting: error).contains("sqlState: 23505"), "\(String(reflecting: error))")
                try await (db as! any TransactionControlDatabase).rollbackTransaction().get()
                #expect(try await Todo.query(on: db).count() == 0)
            } catch {
                try? await CreateTodo().revert(on: db)
                throw error
            }
            try await CreateTodo().revert(on: db)
        } }
    }
    #endif
    
    final class Todo: Model, @unchecked Sendable {
        static let schema = "todos"
        @ID var id
        @Field(key: "title") var title: String
        init() {}
        init(title: String) { self.title = title }
    }

    struct CreateTodo: AsyncMigration {
        func prepare(on database: any Database) async throws { try await database.schema(Todo.schema).id().field("title", .string, .required).unique(on: "title").create() }
        func revert(on database: any Database) async throws { try await database.schema(Todo.schema).delete() }
    }
}
}
