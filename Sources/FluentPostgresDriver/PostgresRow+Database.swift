extension PostgresRow: DatabaseRow {
    public func contains(field: String) -> Bool {
        return self.column(field) != nil
    }

    public func decode<T>(
        field: String,
        as type: T.Type,
        for database: Database
    ) throws -> T where T : Decodable {
        return try self.decode(column: field, as: T.self)
    }
}
