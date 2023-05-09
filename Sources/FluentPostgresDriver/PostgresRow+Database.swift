import PostgresNIO
import PostgresKit
import FluentKit
import SQLKit

extension SQLRow {
    internal func databaseOutput() -> some DatabaseOutput { _PostgresDatabaseOutput(row: self, schema: nil) }
}

private struct _PostgresDatabaseOutput: DatabaseOutput {
    let row: any SQLRow
    let schema: String?
    var description: String { String(describing: self.row) }
    private func adjust(key: FieldKey) -> FieldKey { self.schema.map { .prefix(.prefix(.string($0), "_"), key) } ?? key }
    func schema(_ schema: String) -> any DatabaseOutput { _PostgresDatabaseOutput(row: self.row, schema: schema) }
    func contains(_ key: FieldKey) -> Bool { self.row.contains(column: self.adjust(key: key).description) }
    func decodeNil(_ key: FieldKey) throws -> Bool { try self.row.decodeNil(column: self.adjust(key: key).description) }
    func decode<T: Decodable>(_ key: FieldKey, as: T.Type) throws -> T { try self.row.decode(column: self.adjust(key: key).description, as: T.self) }
}
