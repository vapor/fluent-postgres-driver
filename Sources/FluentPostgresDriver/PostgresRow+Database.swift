import class Foundation.JSONDecoder

extension PostgresRow {
    public func databaseRow(using decoder: PostgresDataDecoder) -> DatabaseRow {
        return _PostgresDatabaseRow(row: self, decoder: decoder)
    }

    public func databaseRow(using decoder: JSONDecoder = JSONDecoder()) -> DatabaseRow {
        return _PostgresDatabaseRow(row: self, decoder: PostgresDataDecoder(jsonDecoder: decoder))
    }
}

private struct _PostgresDatabaseRow: DatabaseRow {
    let row: PostgresRow
    let decoder: PostgresDataDecoder

    var description: String { self.row.description }

    func contains(field: String) -> Bool {
        return self.row.column(field) != nil
    }

    func decode<T>(
        field: String,
        as type: T.Type,
        for database: Database
    ) throws -> T where T : Decodable {
        return try self.row.sqlRow(using: self.decoder).decode(column: field, as: T.self)
    }
}
