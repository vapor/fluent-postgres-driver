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

extension PostgreSQLQuery {
    public struct FluentQuery {
        public enum Statement {
            case insert
            case select
            case update
            case delete
        }
        
        public var statement: Statement
        public var table: TableName
        public var keys: [Key]
        public var values: [String: Value]
        public var joins: [Join]
        public var predicate: Predicate?
        public var orderBy: [OrderBy]
        public var groupBy: [Key]
        public var limit: Int?
        public var offset: Int?
        public var returning: [Key]
        
        public init(
            statement: Statement = .select,
            table: TableName,
            keys: [Key] = [],
            values: [String: Value] = [:],
            joins: [Join] = [],
            predicate: Predicate? = nil,
            orderBy: [OrderBy] = [],
            groupBy: [Key] = [],
            limit: Int? = nil,
            offset: Int? = nil,
            returning: [Key] = []
        ) {
            self.statement = statement
            self.table = table
            self.keys = keys
            self.values = values
            self.joins = joins
            self.predicate = predicate
            self.orderBy = orderBy
            self.groupBy = groupBy
            self.offset = offset
            self.limit = limit
            self.returning = returning
        }
    }
    
    static func fluent(_ fluent: FluentQuery) -> PostgreSQLQuery {
        let query: PostgreSQLQuery
        switch fluent.statement {
        case .insert:
            query = .insert(.init(
                table: fluent.table,
                values: fluent.values,
                returning: fluent.returning
            ))
        case .select:
            query = .select(.init(
                candidates: .all,
                keys: fluent.keys,
                tables: [fluent.table],
                joins: fluent.joins,
                predicate: fluent.predicate,
                orderBy: fluent.orderBy,
                groupBy: fluent.groupBy,
                limit: fluent.limit,
                offset: fluent.offset
            ))
        case .update:
            query = .update(.init(
                locality: .inherited,
                table: fluent.table,
                values: fluent.values,
                predicate: fluent.predicate,
                returning: fluent.returning
            ))
        case .delete:
            query = .delete(.init(
                locality: .inherited,
                table: fluent.table,
                predicate: fluent.predicate,
                returning: fluent.returning
            ))
        }
        return query
    }
}

extension QueryBuilder where Database == PostgreSQLDatabase {
    public func keys(_ keys: PostgreSQLQuery.Key...) -> Self {
        query.keys = keys
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
        return groupBy(.expression(.column(PostgreSQLDatabase.queryField(.keyPath(field)))))
    }
    
    /// Adds a manually created group by to the query builder.
    /// - parameters:
    ///     - groupBy: New `Query.GroupBy` to add.
    /// - returns: Query builder for chaining.
    public func groupBy(_ groupBy: PostgreSQLQuery.Key) -> Self {
        query.groupBy.append(groupBy)
        return self
    }
}


/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: QuerySupporting & JoinSupporting & MigrationSupporting & TransactionSupporting & KeyedCacheSupporting {
    public static var queryJoinMethodDefault: PostgreSQLQuery.Join.Method {
        return .inner
    }
    
    public static func queryJoin(_ method: PostgreSQLQuery.Join.Method, base: PostgreSQLQuery.Column, joined: PostgreSQLQuery.Column) -> PostgreSQLQuery.Join {
        return .init(
            method: method,
            table: .init(name: joined.table!),
            condition: .predicate(base, .equal, .expression(.column(joined)))
        )
    }
    
    public static func queryJoinApply(_ join: PostgreSQLQuery.Join, to query: inout PostgreSQLQuery.FluentQuery) {
        query.joins.append(join)
    }
    
    public static func prepareMigrationMetadata(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public static func query(_ entity: String) -> PostgreSQLQuery.FluentQuery {
        return .init(table: .init(name: entity))
    }
    
    public static func queryEntity(for query: PostgreSQLQuery.FluentQuery) -> String {
        return query.table.name
    }
    
    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> [String : PostgreSQLQuery.Value] where E : Encodable {
        return try PostgreSQLQueryEncoder().encode(encodable)
    }
    
    public static var queryActionCreate: PostgreSQLQuery.FluentQuery.Statement {
        return .insert
    }
    
    public static var queryActionRead: PostgreSQLQuery.FluentQuery.Statement {
        return .select
    }
    
    public static var queryActionUpdate: PostgreSQLQuery.FluentQuery.Statement {
        return .update
    }
    
    public static var queryActionDelete: PostgreSQLQuery.FluentQuery.Statement {
        return .delete
    }
    
    public static func queryActionIsCreate(_ action: PostgreSQLQuery.FluentQuery.Statement) -> Bool {
        switch action {
        case .insert: return true
        default: return false
        }
    }
    
    public static func queryActionApply(_ statement: PostgreSQLQuery.FluentQuery.Statement, to query: inout PostgreSQLQuery.FluentQuery) {
        query.statement = statement
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
    
    public static func queryDataSet(_ column: PostgreSQLQuery.Column, to data: Encodable, on query: inout PostgreSQLQuery.FluentQuery) {
        #warning("Allow query data set to throw if needed.")
        query.values[column.name] = try! .bind(data)
    }
    
    public static func queryDataApply(_ data: [String : PostgreSQLQuery.Value], to query: inout PostgreSQLQuery.FluentQuery) {
        query.values = data
    }
    
    public static func queryField(_ property: FluentProperty) -> PostgreSQLQuery.Column {
        guard let model = property.rootType as? AnyModel.Type else {
            #warning("Fix query field fatal error.")
            fatalError("`\(property.rootType)` does not conform to `Model`.")
        }
        return .init(table: model.entity, name: property.path.first ?? "")
    }
    
    public static var queryFilterMethodEqual: PostgreSQLQuery.Predicate.Comparison {
        return .equal
    }
    
    public static var queryFilterMethodNotEqual: PostgreSQLQuery.Predicate.Comparison {
        return .notEqual
    }
    
    public static var queryFilterMethodGreaterThan: PostgreSQLQuery.Predicate.Comparison {
        return .greaterThan
    }
    
    public static var queryFilterMethodLessThan: PostgreSQLQuery.Predicate.Comparison {
        return .lessThan
    }
    
    public static var queryFilterMethodGreaterThanOrEqual: PostgreSQLQuery.Predicate.Comparison {
        return .greaterThanOrEqual
    }
    
    public static var queryFilterMethodLessThanOrEqual: PostgreSQLQuery.Predicate.Comparison {
        return .lessThanOrEqual
    }
    
    public static var queryFilterMethodInSubset: PostgreSQLQuery.Predicate.Comparison {
        return .in
    }
    
    public static var queryFilterMethodNotInSubset: PostgreSQLQuery.Predicate.Comparison {
        return .notIn
    }
    
    public static func queryFilterValue(_ encodables: [Encodable]) -> PostgreSQLQuery.Value {
        #warning("Fix non throwing binds conversion.")
        return try! .binds(encodables)
    }
    
    public static var queryFilterValueNil: PostgreSQLQuery.Value {
        return .null
    }
    
    public static func queryFilter(_ column: PostgreSQLQuery.Column, _ comparison: PostgreSQLQuery.Predicate.Comparison, _ value: PostgreSQLQuery.Value) -> PostgreSQLQuery.Predicate {
        return .predicate(column, comparison, value)
    }
    
    public static func queryFilters(for query: PostgreSQLQuery.FluentQuery) -> [PostgreSQLQuery.Predicate] {
        
        if let predicate = query.predicate {
            switch predicate {
            case .group(_, let predicates): return predicates
            default: return [predicate]
            }
        } else {
            return []
        }
    }
    
    public static func queryFilterApply(_ filter: PostgreSQLQuery.Predicate, to query: inout PostgreSQLQuery.FluentQuery) {
        if let predicate = query.predicate {
            query.predicate = .group(.and, [predicate, filter])
        } else {
            query.predicate = filter
        }
    }
    
    public static var queryFilterRelationAnd: PostgreSQLQuery.Predicate.Relation {
        return .and
    }
    
    public static var queryFilterRelationOr: PostgreSQLQuery.Predicate.Relation {
        return .or
    }
    
    public static func queryFilterGroup(_ op: PostgreSQLQuery.Predicate.Relation, _ filters: [PostgreSQLQuery.Predicate]) -> PostgreSQLQuery.Predicate {
        return .group(op, filters)
    }
    
    public static var queryKeyAll: PostgreSQLQuery.Key {
        return .all
    }
    
    public static func queryAggregate(_ aggregate: String, _ fields: [PostgreSQLQuery.Key]) -> PostgreSQLQuery.Key {
        return .expression(.function(.init(
            name: aggregate,
            parameters: fields.map { key in
                switch key {
                case .all: return .all
                case .expression(let expression, _): return expression
                }
            }
        )), alias: "fluentAggregate")
    }
    
    public static func queryKey(_ column: PostgreSQLQuery.Column) -> PostgreSQLQuery.Key {
        return .expression(.column(column))
    }
    
    public static func queryKeyApply(_ key: PostgreSQLQuery.Key, to query: inout PostgreSQLQuery.FluentQuery) {
        query.keys.append(key)
    }
    
    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout PostgreSQLQuery.FluentQuery) {
        if let upper = upper {
            query.limit = upper - lower
            query.offset = lower
        } else {
            query.offset = lower
        }
    }
    
    public static func querySort(_ column: PostgreSQLQuery.Column, _ direction: PostgreSQLQuery.OrderBy.Direction) -> PostgreSQLQuery.OrderBy {
        return .init(columns: [column], direction: direction)
    }
    
    public static var querySortDirectionAscending: PostgreSQLQuery.OrderBy.Direction {
        return .ascending
    }
    
    public static var querySortDirectionDescending: PostgreSQLQuery.OrderBy.Direction {
        return .descending
    }
    
    public static func querySortApply(_ orderBy: PostgreSQLQuery.OrderBy, to query: inout PostgreSQLQuery.FluentQuery) {
        query.orderBy.append(orderBy)
    }
    
    /// See `SQLDatabase`.
    public typealias QueryJoin = PostgreSQLQuery.Join
    
    /// See `SQLDatabase`.
    public typealias QueryJoinMethod = PostgreSQLQuery.Join.Method
    
    /// See `SQLDatabase`.
    public typealias Query = PostgreSQLQuery.FluentQuery
    
    /// See `SQLDatabase`.
    public typealias Output = [PostgreSQLColumn: PostgreSQLData]
    
    /// See `SQLDatabase`.
    public typealias QueryAction = PostgreSQLQuery.FluentQuery.Statement
    
    /// See `SQLDatabase`.
    public typealias QueryAggregate = String
    
    /// See `SQLDatabase`.
    public typealias QueryData = [String: PostgreSQLQuery.Value]
    
    /// See `SQLDatabase`.
    public typealias QueryField = PostgreSQLQuery.Column
    
    /// See `SQLDatabase`.
    public typealias QueryFilterMethod = PostgreSQLQuery.Predicate.Comparison
    
    /// See `SQLDatabase`.
    public typealias QueryFilterValue = PostgreSQLQuery.Value
    
    /// See `SQLDatabase`.
    public typealias QueryFilter = PostgreSQLQuery.Predicate
    
    /// See `SQLDatabase`.
    public typealias QueryFilterRelation = PostgreSQLQuery.Predicate.Relation
    
    /// See `SQLDatabase`.
    public typealias QueryKey = PostgreSQLQuery.Key
    
    /// See `SQLDatabase`.
    public typealias QuerySort = PostgreSQLQuery.OrderBy
    
    /// See `SQLDatabase`.
    public typealias QuerySortDirection = PostgreSQLQuery.OrderBy.Direction
    
    /// See `SQLDatabase`.
    public static func queryExecute(
        _ query: PostgreSQLQuery.FluentQuery,
        on conn: PostgreSQLConnection,
        into handler: @escaping ([PostgreSQLColumn: PostgreSQLData], PostgreSQLConnection) throws -> ()
    ) -> Future<Void> {
        var query = query
        switch query.statement {
        case .insert:
            // if statement is `INSERT`, then replace any `NULL` values with `DEFAULT`
            // that will act as `NULL` while not causing problems with primary keys or fields
            // with NOT NULL constraint _and_ default values.
            query.values = query.values.mapValues { value in
                switch value {
                case .null: return .default
                default: return value
                }
            }
            query.returning.append(.all)
        default: break
        }
        // always cache the names first
        return conn.tableNames().flatMap { names in
            return conn.query(.fluent(query)) { row in
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
        default: break
        }

        return conn.future(model)
    }
    
    /// See `SchemaSupporting`.
    public static func schemaExecute(_ schema: PostgreSQLQuery.FluentSchema, on connection: PostgreSQLConnection) -> Future<Void> {
        return connection.query(.fluent(schema)).transform(to: ())
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
