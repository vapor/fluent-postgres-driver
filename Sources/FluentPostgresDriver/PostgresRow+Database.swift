import class Foundation.JSONDecoder

extension PostgresRow {
    internal func databaseRow(using decoder: PostgresDataDecoder) -> DatabaseRow {
        return _PostgresDatabaseRow(row: self, decoder: decoder)
    }
}

private struct _PostgresDatabaseRow: DatabaseRow {
    let row: PostgresRow
    let decoder: PostgresDataDecoder

    var description: String { self.row.description }

    func contains(field: FieldKey) -> Bool {
        return self.row.column(field.description) != nil
    }

    func decode<T>(
        field: FieldKey,
        as type: T.Type,
        for database: Database
    ) throws -> T where T : Decodable {
        return try self.row.sql(decoder: self.decoder).decode(column: field.description, as: T.self)
    }
}
