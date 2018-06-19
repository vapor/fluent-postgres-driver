@_exported import FluentSQL
@_exported import PostgreSQL

//extension QueryBuilder where Database == PostgreSQLDatabase {
//    public func keys(_ keys: PostgreSQLQuery.Key...) -> Self {
//        query.keys = keys
//        return self
//    }
//
//    // MARK: Group By
//
//    /// Adds a group by to the query builder.
//    ///
//    ///     query.groupBy(\.name)
//    ///
//    /// - parameters:
//    ///     - field: Swift `KeyPath` to field on model to group by.
//    /// - returns: Query builder for chaining.
//    public func groupBy<T>(_ field: KeyPath<Result, T>) -> Self {
//        return groupBy(.expression(.column(PostgreSQLDatabase.queryField(.keyPath(field))), alias: nil))
//    }
//
//    /// Adds a manually created group by to the query builder.
//    /// - parameters:
//    ///     - groupBy: New `Query.GroupBy` to add.
//    /// - returns: Query builder for chaining.
//    public func groupBy(_ groupBy: PostgreSQLQuery.Key) -> Self {
//        query.groupBy.append(groupBy)
//        return self
//    }
//}
