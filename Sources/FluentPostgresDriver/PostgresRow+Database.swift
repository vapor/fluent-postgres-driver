import class Foundation.JSONDecoder

extension PostgresRow {
    internal func databaseOutput(using decoder: PostgresDataDecoder) -> DatabaseOutput {
        _PostgresDatabaseOutput(
            row: self,
            decoder: decoder
        )
    }
}

private struct _PostgresDatabaseOutput: DatabaseOutput {
    let row: PostgresRow
    let decoder: PostgresDataDecoder

    var description: String {
        self.row.description
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        if let data = self.row.column(self.columnName(key)) {
            return data.type == .null
        } else {
            return true
        }
    }

    func contains(_ key: FieldKey) -> Bool {
        self.row.column(self.columnName(key)) != nil
    }

    func schema(_ schema: String) -> DatabaseOutput {
        _SchemaDatabaseOutput(
            output: self,
            schema: schema
        )
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.row.sql(decoder: self.decoder)
            .decode(column: self.columnName(key), as: T.self)
    }

    func columnName(_ key: FieldKey) -> String {
        switch key {
        case .id:
            return "id"
        case .aggregate:
            return key.description
        case .string(let name):
            return name
        case .prefix(let prefix, let key):
            return self.columnName(prefix) + self.columnName(key)
        }
    }
}

private struct _SchemaDatabaseOutput: DatabaseOutput {
    let output: DatabaseOutput
    let schema: String

    var description: String {
        self.output.description
    }

    func schema(_ schema: String) -> DatabaseOutput {
        self.output.schema(schema)
    }

    func contains(_ key: FieldKey) -> Bool {
        self.output.contains(self.key(key))
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.output.decodeNil(self.key(key))
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T
        where T: Decodable
    {
        try self.output.decode(self.key(key), as: T.self)
    }

    private func key(_ key: FieldKey) -> FieldKey {
        .prefix(.string(self.schema + "_"), key)
    }
}
