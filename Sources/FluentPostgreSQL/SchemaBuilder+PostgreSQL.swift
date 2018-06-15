extension SchemaBuilder where Model.Database == PostgreSQLDatabase {
    public func field<T>(
        for keyPath: KeyPath<Model, T>,
        type dataType: PostgreSQLQuery.DataType,
        isArray: Bool = false,
        collate: String? = nil,
        _ constraints: PostgreSQLQuery.ColumnConstraint...
    ) {
        let property = FluentProperty.keyPath(keyPath)
        let columnDefinition = PostgreSQLQuery.ColumnDefinition.init(
            name: property.path[0],
            dataType: dataType,
            isArray: isArray,
            collate: collate,
            constraints: constraints
        )
        schema.createColumns.append(columnDefinition)
    }
}
