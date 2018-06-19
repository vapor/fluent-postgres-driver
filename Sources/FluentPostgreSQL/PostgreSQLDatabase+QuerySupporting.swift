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
            var values: [PostgreSQLExpression] = []
            fluent.values.forEach { row in
                // filter out all `NULL` values, no need to insert them since
                // they could override default values that we want to keep
                switch row.value {
                case ._literal(let literal):
                    switch literal {
                    case ._null: return
                    default: break
                    }
                default: break
                }
                insert.columns.append(.column(nil, .identifier(row.key)))
                values.append(row.value)
            }
            insert.values.append(values)
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
            select.limit = fluent.limit
            select.offset = fluent.offset
            query = .select(select)
        case ._update:
            var update: PostgreSQLUpdate = .update(fluent.table)
            update.table = fluent.table
            update.values = fluent.values.map { val in
                return (.identifier(val.key), val.value)
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
    public static func schemaExecute(_ fluent: FluentPostgreSQLSchema, on conn: PostgreSQLConnection) -> Future<Void> {
        let query: PostgreSQLQuery
        switch fluent.statement {
        case ._createTable:
            var createTable: PostgreSQLCreateTable = .createTable(fluent.table)
            createTable.columns = fluent.columns
            createTable.tableConstraints = fluent.constraints
            query = ._createTable(createTable)
        case ._alterTable:
            var alterTable: PostgreSQLAlterTable = .alterTable(fluent.table)
            alterTable.columns = fluent.columns
            alterTable.constraints = fluent.constraints
            query = ._alterTable(alterTable)
        case ._dropTable:
            let dropTable: PostgreSQLDropTable = .dropTable(fluent.table)
            query = ._dropTable(dropTable)
        }
        return conn.query(query).transform(to: ())
    }
}
