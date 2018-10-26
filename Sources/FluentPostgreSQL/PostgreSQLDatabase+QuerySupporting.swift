/// Adds ability to do basic Fluent queries using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: QuerySupporting {
    /// See `SQLDatabase`.
    public typealias Query = FluentPostgreSQLQuery
    
    /// See `SQLDatabase`.
    public typealias Output = [PostgreSQLColumn: PostgreSQLData]
    
    /// See `SQLDatabase`.
    public typealias QueryAction = FluentPostgreSQLQueryStatement
    
    /// See `SQLDatabase`.
    public typealias QueryAggregate = String
    
    /// See `SQLDatabase`.
    public typealias QueryData = [String: PostgreSQLExpression]
    
    /// See `SQLDatabase`.
    public typealias QueryField = PostgreSQLColumnIdentifier
    
    /// See `SQLDatabase`.
    public typealias QueryFilterMethod = PostgreSQLBinaryOperator
    
    /// See `SQLDatabase`.
    public typealias QueryFilterValue = PostgreSQLExpression
    
    /// See `SQLDatabase`.
    public typealias QueryFilter = PostgreSQLExpression
    
    /// See `SQLDatabase`.
    public typealias QueryFilterRelation = PostgreSQLBinaryOperator
    
    /// See `SQLDatabase`.
    public typealias QueryKey = PostgreSQLSelectExpression
    
    /// See `SQLDatabase`.
    public typealias QuerySort = PostgreSQLOrderBy
    
    /// See `SQLDatabase`.
    public typealias QuerySortDirection = PostgreSQLDirection
    
    /// See `SQLDatabase`.
    public static func queryExecute(
        _ fluent: FluentPostgreSQLQuery,
        on conn: PostgreSQLConnection,
        into handler: @escaping ([PostgreSQLColumn: PostgreSQLData], PostgreSQLConnection) throws -> ()
    ) -> Future<Void> {
        let query: PostgreSQLQuery
        switch fluent.statement {
        case ._insert:
            var insert: PostgreSQLInsert = .insert(fluent.table)
            
            if let firstRow = fluent.values.first {
                insert.columns.append(contentsOf: firstRow.columns())
                fluent.values.forEach { value in
                    let row = value.postgresExpression()
                    insert.values.append(row)
                }
            }
            
            insert.upsert = fluent.upsert
            insert.returning.append(.all)
            query = .insert(insert)
        case ._select:
            var select: PostgreSQLSelect = .select()
            select.columns = fluent.keys.isEmpty ? [.all] : fluent.keys
            select.tables = [fluent.table]
            select.joins = fluent.joins
            select.predicate = fluent.predicate
            select.orderBy = fluent.orderBy
            select.groupBy = fluent.groupBy
            select.limit = fluent.limit
            select.offset = fluent.offset
            query = .select(select)
        case ._update:
            var update: PostgreSQLUpdate = .update(fluent.table)
            update.table = fluent.table
            
            if let row = fluent.values.first {
                update.values = row.map { val in (.identifier(val.key), val.value) }
            }
            
            update.predicate = fluent.predicate
            query = .update(update)
        case ._delete:
            var delete: PostgreSQLDelete = .delete(fluent.table)
            delete.predicate = fluent.predicate
            query = .delete(delete)
        }
        return conn.query(query) { try handler($0, conn) }
    }

    struct InsertMetadata<ID>: Codable where ID: Codable {
        var lastval: ID
    }
    
    /// See `QuerySupporting`.
    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: PostgreSQLConnection) -> Future<M>
        where PostgreSQLDatabase == M.Database, M: Model
    {
        switch event {
        case .willCreate:
            if M.ID.self == UUID.self, model.fluentID == nil {
                var model = model
                model.fluentID = UUID() as? M.ID
                return conn.future(model)
            }
        default: break
        }

        return conn.future(model)
    }
}

extension Dictionary where Key == String, Value == FluentPostgreSQLQuery.Expression {
    func postgresExpression() -> [PostgreSQLExpression] {
        return self.map { pair -> PostgreSQLExpression in
            switch pair.value {
            case ._literal(let literal):
                switch literal {
                case ._null: return .literal(.default)
                default: return pair.value
                }
            default: return pair.value
            }
        }
    }
    
    func columns() -> [PostgreSQLColumnIdentifier] {
        return self.map { .column(nil, .identifier($0.key)) }
    }
}
