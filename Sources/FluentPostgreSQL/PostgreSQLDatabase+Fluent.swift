infix operator ~=
/// Has prefix
public func ~= <Result>(lhs: KeyPath<Result, String>, rhs: String) -> FilterOperator<PostgreSQLDatabase, Result> {
    return .make(lhs, .like, ["%" + rhs])
}
/// Has prefix
public func ~= <Result>(lhs: KeyPath<Result, String?>, rhs: String) -> FilterOperator<PostgreSQLDatabase, Result> {
    return .make(lhs, .like, ["%" + rhs])
}

infix operator =~
/// Has suffix.
public func =~ <Result>(lhs: KeyPath<Result, String>, rhs: String) -> FilterOperator<PostgreSQLDatabase, Result> {
    return .make(lhs, .like, [rhs + "%"])
}
/// Has suffix.
public func =~ <Result>(lhs: KeyPath<Result, String?>, rhs: String) -> FilterOperator<PostgreSQLDatabase, Result> {
    return .make(lhs, .like, [rhs + "%"])
}

infix operator ~~
/// Contains.
public func ~~ <Result>(lhs: KeyPath<Result, String>, rhs: String) -> FilterOperator<PostgreSQLDatabase, Result> {
    return .make(lhs, .like, ["%" + rhs + "%"])
}
/// Contains.
public func ~~ <Result>(lhs: KeyPath<Result, String?>, rhs: String) -> FilterOperator<PostgreSQLDatabase, Result> {
    return .make(lhs, .like, ["%" + rhs + "%"])
}


public enum PostgreSQLQueryAction {
    case create
    case read
    case update
    case delete
}

extension QueryBuilder where Database == PostgreSQLDatabase {
    public func select(_ keys: PostgreSQLQuery.Expression...) -> Self {
        switch query {
        case .select(var select):
            select.keys = keys
            query = .select(select)
        default: break
        }
        return self
    }
    
    // MARK: Group By
    
    /// Adds a group by to the query builder.
    ///
    ///     query.groupBy(\.name)
    ///
    /// - parameters:
    ///     - field: Swift `KeyPath` to field on model to group by.
    /// - returns: Query builder for chaining.
    public func groupBy<T>(_ field: KeyPath<Result, T>) -> Self {
        return groupBy(.column(PostgreSQLDatabase.queryField(.keyPath(field))))
    }
    
    /// Adds a manually created group by to the query builder.
    /// - parameters:
    ///     - groupBy: New `Query.GroupBy` to add.
    /// - returns: Query builder for chaining.
    public func groupBy(_ groupBy: PostgreSQLQuery.Expression) -> Self {
        switch query {
        case .select(var select):
            select.groupBys.append(groupBy)
            query = .select(select)
        default: break
        }
        return self
    }
}


/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: QuerySupporting & JoinSupporting & MigrationSupporting & TransactionSupporting & KeyedCacheSupporting {
    public static var queryJoinMethodDefault: PostgreSQLQuery.DML.Join.Method {
        return .inner
    }
    
    public static func queryJoin(_ method: PostgreSQLQuery.DML.Join.Method, base: PostgreSQLQuery.Column, joined: PostgreSQLQuery.Column) -> PostgreSQLQuery.DML.Join {
        return .init(method: method, local: base, foreign: joined)
    }
    
    public static func queryJoinApply(_ join: PostgreSQLQuery.DML.Join, to query: inout PostgreSQLQuery.DML) {
        switch query {
        case .insert: break
        case .select(var select):
            select.joins.append(join)
            query = .select(select)
        }
    }
    
    public static func prepareMigrationMetadata(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public static func query(_ entity: String) -> PostgreSQLQuery.DML {
        return .select(.init(tables: [.init(name: entity)]))
    }
    
    public static func queryEntity(for query: PostgreSQLQuery.DML) -> String {
        switch query {
        case .insert(let insert): return insert.table.name
        case .select(let select): return select.tables.first?.name ?? ""
        }
    }
    
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [String : PostgreSQLQuery.DML.Value] where E : Encodable {
        return try PostgreSQLQueryEncoder().encode(encodable)
    }
    
    public static var queryActionCreate: PostgreSQLQueryAction {
        return .create
    }
    
    public static var queryActionRead: PostgreSQLQueryAction {
        return .read
    }
    
    public static var queryActionUpdate: PostgreSQLQueryAction {
        return .update
    }
    
    public static var queryActionDelete: PostgreSQLQueryAction {
        return .delete
    }
    
    public static func queryActionIsCreate(_ action: PostgreSQLQueryAction) -> Bool {
        switch action {
        case .create: return true
        default: return false
        }
    }
    
    public static func queryActionApply(_ action: PostgreSQLQueryAction, to query: inout PostgreSQLQuery.DML) {
        switch action {
        case .create:
            switch query {
            case .select(let select): query = .insert(.init(table: select.tables.first!, values: [:]))
            default: break
            }
        case .update: break
        case .read: break
        case .delete: break
        }
    }
    
    public static var queryAggregateCount: String {
        return "COUNT"
    }
    
    public static var queryAggregateSum: String {
        return "SUM"
    }
    
    public static var queryAggregateAverage: String {
        return "AVG"
    }
    
    public static var queryAggregateMinimum: String {
        return "MIN"
    }
    
    public static var queryAggregateMaximum: String {
        return "MAX"
    }
    
    public static func queryDataSet(_ column: PostgreSQLQuery.Column, to data: Encodable, on query: inout PostgreSQLQuery.DML) {
        switch query {
        case .insert(var insert):
            #warning("Fix non-throwable query data conversion.")
            insert.values[column.name] = try! .bind(data)
            query = .insert(insert)
        case .select: break
        }
    }
    
    public static func queryDataApply(_ data: [String : PostgreSQLQuery.DML.Value], to query: inout PostgreSQLQuery.DML) {
        switch query {
        case .insert(var insert):
            insert.values = data
            query = .insert(insert)
        case .select: break
        }
    }
    
    public static func queryField(_ property: FluentProperty) -> PostgreSQLQuery.Column {
        guard let model = property.rootType as? AnyModel.Type else {
            #warning("Fix query field fatal error.")
            fatalError("`\(property.rootType)` does not conform to `Model`.")
        }
        return .init(table: model.entity, name: property.path.first ?? "")
    }
    
    public static var queryFilterMethodEqual: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .equal
    }
    
    public static var queryFilterMethodNotEqual: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .notEqual
    }
    
    public static var queryFilterMethodGreaterThan: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .greaterThan
    }
    
    public static var queryFilterMethodLessThan: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .lessThan
    }
    
    public static var queryFilterMethodGreaterThanOrEqual: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .greaterThanOrEqual
    }
    
    public static var queryFilterMethodLessThanOrEqual: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .lessThanOrEqual
    }
    
    public static var queryFilterMethodInSubset: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .in
    }
    
    public static var queryFilterMethodNotInSubset: PostgreSQLQuery.DML.Predicate.ComparisonOperator {
        return .notIn
    }
    
    public static func queryFilterValue(_ encodables: [Encodable]) -> PostgreSQLQuery.DML.Value {
        #warning("Fix non throwing binds conversion.")
        return try! .binds(encodables)
    }
    
    public static var queryFilterValueNil: PostgreSQLQuery.DML.Value {
        return .null
    }
    
    public static func queryFilter(_ column: PostgreSQLQuery.Column, _ comparison: PostgreSQLQuery.DML.Predicate.ComparisonOperator, _ value: PostgreSQLQuery.DML.Value) -> PostgreSQLQuery.DML.Predicate {
        return .predicate(column, comparison, value)
    }
    
    public static func queryFilters(for query: PostgreSQLQuery.DML) -> [PostgreSQLQuery.DML.Predicate] {
        switch query {
        case .insert: return []
        case .select(let select):
            if let predicate = select.predicate {
                return [predicate]
            } else {
                return []
            }
        }
    }
    
    public static func queryFilterApply(_ filter: PostgreSQLQuery.DML.Predicate, to query: inout PostgreSQLQuery.DML) {
        switch query {
        case .select(var select):
            if let predicate = select.predicate {
                select.predicate = predicate && filter
            } else {
                select.predicate = filter
            }
            query = .select(select)
        default: break
        }
    }
    
    public static var queryFilterRelationAnd: PostgreSQLQuery.DML.Predicate.InfixOperator {
        return .and
    }
    
    public static var queryFilterRelationOr: PostgreSQLQuery.DML.Predicate.InfixOperator {
        return .or
    }
    
    public static func queryFilterGroup(_ op: PostgreSQLQuery.DML.Predicate.InfixOperator, _ filters: [PostgreSQLQuery.DML.Predicate]) -> PostgreSQLQuery.DML.Predicate {
        switch filters.count {
        case 0: fatalError("No filters added.")
        case 1: return filters[0]
        case 2: return .infix(op, filters[0], filters[1])
        default: return .infix(op, filters[0], queryFilterGroup(op, .init(filters[1...])))
        }
    }
    
    public static var queryKeyAll: PostgreSQLQuery.Expression {
        return .all
    }
    
    public static func queryAggregate(_ aggregate: String, _ fields: [PostgreSQLQuery.Expression]) -> PostgreSQLQuery.Expression {
        return .function(aggregate, fields, as: "fluentAggregate")
    }
    
    public static func queryKey(_ column: PostgreSQLQuery.Column) -> PostgreSQLQuery.Expression {
        return .column(column)
    }
    
    public static func queryKeyApply(_ key: PostgreSQLQuery.Expression, to query: inout PostgreSQLQuery.DML) {
        switch query {
        case .select(var select):
            select.keys.append(key)
            query = .select(select)
        case .insert: break
        }
    }
    
    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout PostgreSQLQuery.DML) {
        switch query {
        case .select(var select):
            if let upper = upper {
                select.limit = upper - lower
                select.offset = lower
            } else {
                select.offset = lower
            }
            query = .select(select)
        case .insert: break
        }
    }
    
    public static func querySort(_ column: PostgreSQLQuery.Column, _ direction: PostgreSQLQuery.DML.OrderBy.Direction) -> PostgreSQLQuery.DML.OrderBy {
        return .init(columns: [column], direction: direction)
    }
    
    public static var querySortDirectionAscending: PostgreSQLQuery.DML.OrderBy.Direction {
        return .ascending
    }
    
    public static var querySortDirectionDescending: PostgreSQLQuery.DML.OrderBy.Direction {
        return .descending
    }
    
    public static func querySortApply(_ orderBy: PostgreSQLQuery.DML.OrderBy, to query: inout PostgreSQLQuery.DML) {
        switch query {
        case .select(var select):
            select.orderBys.append(orderBy)
            query = .select(select)
        default: break
        }
    }
    
    /// See `SQLDatabase`.
    public typealias QueryJoin = PostgreSQLQuery.DML.Join
    
    /// See `SQLDatabase`.
    public typealias QueryJoinMethod = PostgreSQLQuery.DML.Join.Method
    
    /// See `SQLDatabase`.
    public typealias Query = PostgreSQLQuery.DML
    
    /// See `SQLDatabase`.
    public typealias Output = [PostgreSQLColumn: PostgreSQLData]
    
    /// See `SQLDatabase`.
    public typealias QueryAction = PostgreSQLQueryAction
    
    /// See `SQLDatabase`.
    public typealias QueryAggregate = String
    
    /// See `SQLDatabase`.
    public typealias QueryData = [String: PostgreSQLQuery.DML.Value]
    
    /// See `SQLDatabase`.
    public typealias QueryField = PostgreSQLQuery.Column
    
    /// See `SQLDatabase`.
    public typealias QueryFilterMethod = PostgreSQLQuery.DML.Predicate.ComparisonOperator
    
    /// See `SQLDatabase`.
    public typealias QueryFilterValue = PostgreSQLQuery.DML.Value
    
    /// See `SQLDatabase`.
    public typealias QueryFilter = PostgreSQLQuery.DML.Predicate
    
    /// See `SQLDatabase`.
    public typealias QueryFilterRelation = PostgreSQLQuery.DML.Predicate.InfixOperator
    
    /// See `SQLDatabase`.
    public typealias QueryKey = PostgreSQLQuery.Expression
    
    /// See `SQLDatabase`.
    public typealias QuerySort = PostgreSQLQuery.DML.OrderBy
    
    /// See `SQLDatabase`.
    public typealias QuerySortDirection = PostgreSQLQuery.DML.OrderBy.Direction
    
    /// See `SQLDatabase`.
    public static func queryExecute(
        _ query: PostgreSQLQuery.DML,
        on conn: PostgreSQLConnection,
        into handler: @escaping ([PostgreSQLColumn: PostgreSQLData], PostgreSQLConnection) throws -> ()
    ) -> Future<Void> {
        // always cache the names first
        return conn.tableNames().flatMap { names in
            return conn.query(.dml(query)) { row in
                try handler(row, conn)
            }
        }
    }
    
    /// See `SQLDatabase`.
    public static func queryDecode<D>(_ data: [PostgreSQLColumn: PostgreSQLData], entity: String, as decodable: D.Type, on conn: PostgreSQLConnection) -> Future<D>
        where D: Decodable
    {
        return conn.tableNames().map { names in
            return try PostgreSQLRowDecoder().decode(D.self, from: data, tableOID: names.tableOID(name: entity) ?? 0)
        }
    }

    struct InsertMetadata<ID>: Codable where ID: Codable {
        var lastval: ID
    }
    
    /// See `QuerySupporting.modelEvent`
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: PostgreSQLConnection) -> Future<M>
        where PostgreSQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self {
                var model = model
                model.fluentID = UUID() as? M.ID
                return conn.future(model)
            }
        case .didCreate:
            if M.ID.self == Int.self, model.fluentID == nil {
                return conn.simpleQuery("SELECT LASTVAL();", decoding: InsertMetadata<M.ID>.self).map { rows in
                    switch rows.count {
                    case 1:
                        var model = model
                        model.fluentID = rows[0].lastval
                        return model
                    default: throw PostgreSQLError(identifier: "lastval", reason: "Unexpected row count when querying LASTVAL.")
                    }
                }
            }
        default: break
        }

        return conn.future(model)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaExecute(_ ddl: PostgreSQLQuery.DDL, on connection: PostgreSQLConnection) -> Future<Void> {
        return connection.query(.ddl(ddl)).transform(to: ())
    }
    
    
    /// See `SchemaSupporting`.
    public static func enableForeignKeys(on connection: PostgreSQLConnection) -> Future<Void> {
        // enabled by default
        return .done(on: connection)
    }
    
    /// See `SchemaSupporting`.
    public static func disableForeignKeys(on connection: PostgreSQLConnection) -> Future<Void> {
        return Future.map(on: connection) {
            throw PostgreSQLError(identifier: "disableReferences", reason: "PostgreSQL does not support disabling foreign key checks.")
        }
    }
    
    /// See `SchemaSupporting`.
    public static func transactionExecute<T>(_ transaction: @escaping (PostgreSQLConnection) throws -> Future<T>, on connection: PostgreSQLConnection) -> Future<T> {
        return connection.simpleQuery("BEGIN TRANSACTION").flatMap { results in
            return try transaction(connection).flatMap { res in
                return connection.simpleQuery("END TRANSACTION").transform(to: res)
            }.catchFlatMap { error in
                return connection.simpleQuery("ROLLBACK").map { results in
                    throw error
                }
            }
        }
    }
}
