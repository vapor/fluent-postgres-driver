extension _PostgreSQLModel {
    public func create(orUpdate: Bool, on conn: DatabaseConnectable) -> Future<Self> {
        return Self.query(on: conn).create(orUpdate: orUpdate, self)
    }
}

extension QueryBuilder where Result: _PostgreSQLModel, Result.Database == Database {
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
