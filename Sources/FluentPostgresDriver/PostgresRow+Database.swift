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

    func contains(_ field: FieldKey) -> Bool {
        return self.row.column(self.column(field)) != nil
    }

    func schema(_ schema: String) -> DatabaseOutput {
        _PostgresDatabaseOutput(
            row: self.row,
            decoder: self.decoder,
            schema: schema
        )
    }

    func decode<T>(
        _ field: FieldKey,
        as type: T.Type
    ) throws -> T where T : Decodable {
        try self.row.sql(decoder: self.decoder)
            .decode(column: self.column(field), as: T.self)
    }

    private func column(_ field: FieldKey) -> String {
        if let schema = self.schema {
            return schema + "_" + field.description
        } else {
            return field.description
        }
    }
}
