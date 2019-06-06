extension PostgresRow: DatabaseOutput {
    public func contains(field: String) -> Bool {
        return self.column(field) != nil
    }

    public func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
        return try self.decode(column: field, as: T.self)
    }
}
