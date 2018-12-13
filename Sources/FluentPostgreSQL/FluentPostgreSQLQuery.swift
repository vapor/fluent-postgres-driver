public enum FluentPostgreSQLQueryStatement: FluentSQLQueryStatement {
    public static var insert: FluentPostgreSQLQueryStatement { return ._insert }
    public static var select: FluentPostgreSQLQueryStatement { return ._select }
    public static var update: FluentPostgreSQLQueryStatement { return ._update }
    public static var delete: FluentPostgreSQLQueryStatement { return ._delete }
    
    public var isInsert: Bool {
        switch self {
        case ._insert: return true
        default: return false
        }
    }
    
    case _insert
    case _select
    case _update
    case _delete
}

public struct FluentPostgreSQLQuery: FluentSQLQuery {
    public typealias Statement = FluentPostgreSQLQueryStatement
    public typealias Distinct = PostgreSQLDistinct
    public typealias TableIdentifier = PostgreSQLTableIdentifier
    public typealias Expression = PostgreSQLExpression
    public typealias SelectExpression = PostgreSQLSelectExpression
    public typealias Join = PostgreSQLJoin
    public typealias OrderBy = PostgreSQLOrderBy
    public typealias GroupBy = PostgreSQLGroupBy
    public typealias Upsert = PostgreSQLUpsert
    
    public var statement: Statement
    public var distinct: Distinct?
    public var table: TableIdentifier
    public var keys: [SelectExpression]
    public var values: [String : Expression]
    public var joins: [Join]
    public var predicate: Expression?
    public var orderBy: [OrderBy]
    public var groupBy: [GroupBy]
    public var limit: Int?
    public var offset: Int?
    public var upsert: PostgreSQLUpsert?
    public var defaultBinaryOperator: PostgreSQLBinaryOperator
    
    public static func query(_ statement: Statement, _ table: TableIdentifier) -> FluentPostgreSQLQuery {
        return .init(
            statement: statement,
            distinct: nil,
            table: table,
            keys: [],
            values: [:],
            joins: [],
            predicate: nil,
            orderBy: [],
            groupBy: [],
            limit: nil,
            offset: nil,
            upsert: nil,
            defaultBinaryOperator: .and
        )
    }
}
