extension _PostgreSQLModel {
    /// Creates the model or updates it depending on whether a model with the same ID already exists.
    public func create(orUpdate: Bool, on conn: DatabaseConnectable) -> Future<Self> {
        return Self.query(on: conn).create(orUpdate: orUpdate, self)
    }
}

extension QueryBuilder where Result: _PostgreSQLModel, Result.Database == Database {
    /// Creates the model or updates it depending on whether a model with the same ID already exists.
    public func create(orUpdate: Bool, _ model: Result) -> Future<Result> {
        if orUpdate {
            let row = SQLQueryEncoder(PostgreSQLExpression.self).encode(model)
            let values = row.map { row -> (PostgreSQLIdentifier, PostgreSQLExpression) in
                return (.identifier(row.key), row.value)
            }
            self.query.upsert = .upsert([.keyPath(Result.idKey)], values)
        }
        return create(model)
    }
    
}
