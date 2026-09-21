import FluentSQL

// These are common methods that _FluentPostgresClientDatabase's and the legacy `_FluentPostgresDatabase` share.
extension Database where Self: SQLDatabase {
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> Void
    ) -> EventLoopFuture<Void> {
        var expression = SQLQueryConverter(delegate: PostgresConverterDelegate()).convert(query)

        /// For `.create` query actions, we want to return the generated IDs, unless the `customIDKey` is the
        /// empty string, which we use as a very hacky signal for "we don't implement this for composite IDs yet".
        if case .create = query.action, query.customIDKey != .some(.string("")) {
            expression = SQLKit.SQLList([expression, SQLReturning(.init((query.customIDKey ?? .id).description))], separator: SQLRaw(" "))
        }

        return self.execute(sql: expression, { onOutput($0.databaseOutput()) })
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let expression = SQLSchemaConverter(delegate: PostgresConverterDelegate()).convert(schema)

        return self.execute(
            sql: expression,
            // N.B.: Don't fatalError() here; what're users supposed to do about it?
            { self.logger.debug("Unexpected row returned from schema query: \($0)") }
        )
    }

    func execute(enum e: FluentKit.DatabaseEnum) -> NIOCore.EventLoopFuture<Void> {
        switch e.action {
        case .create:
            return e.createCases.reduce(self.create(enum: e.name)) { $0.value($1) }.run()
        case .update:
            if !e.deleteCases.isEmpty {
                self.logger.debug("PostgreSQL does not support deleting enum cases.")
            }
            guard !e.createCases.isEmpty else {
                return self.eventLoop.makeSucceededFuture(())
            }

            return self.eventLoop.flatten(
                e.createCases.map { create in
                    self.alter(enum: e.name).add(value: create).run()
                }
            )
        case .delete:
            return self.drop(enum: e.name).run()
        }
    }
}
