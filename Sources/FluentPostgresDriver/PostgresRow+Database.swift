import class Foundation.JSONDecoder

extension PostgresRow {
    internal func databaseOutput(using decoder: PostgresDataDecoder) -> DatabaseOutput {
        _PostgresDatabaseOutput(
            row: self,
            decoder: decoder,
            schema: nil
        )
    }
}

private struct _PostgresDatabaseOutput: DatabaseOutput {
    let row: PostgresRow
    let decoder: PostgresDataDecoder
    let schema: String?

    var description: String {
        self.row.description
    }

    func contains(_ path: [FieldKey]) -> Bool {
        return self.row.column(self.columnName(path)) != nil
    }

    func schema(_ schema: String) -> DatabaseOutput {
        _PostgresDatabaseOutput(
            row: self.row,
            decoder: self.decoder,
            schema: schema
        )
    }

    func decode<T>(
        _ path: [FieldKey],
        as type: T.Type
    ) throws -> T where T : Decodable {
        try self.row.sql(decoder: self.decoder)
            .decode(column: self.columnName(path), as: T.self)
    }

    private func columnName(_ path: [FieldKey]) -> String {
        let field = path.map { $0.description }.joined(separator: "_")
        if let schema = self.schema {
            return "\(schema)_\(field)"
        } else {
            return field
        }

    }
}
