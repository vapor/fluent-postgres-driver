public enum FluentPostgreSQLSchemaStatement: FluentSQLSchemaStatement {
    public static var createTable: FluentPostgreSQLSchemaStatement { return ._createTable }
    public static var alterTable: FluentPostgreSQLSchemaStatement { return ._alterTable }
    public static var dropTable: FluentPostgreSQLSchemaStatement { return ._dropTable }
    
    case _createTable
    case _alterTable
    case _dropTable
}

public struct FluentPostgreSQLSchema: FluentSQLSchema {
    public typealias Statement = FluentPostgreSQLSchemaStatement
    public typealias TableIdentifier = PostgreSQLTableIdentifier
    public typealias ColumnDefinition = PostgreSQLColumnDefinition
    public typealias TableConstraint = PostgreSQLTableConstraint
    
    public var statement: Statement
    public var table: TableIdentifier
    public var columns: [PostgreSQLColumnDefinition]
    public var deleteColumns: [PostgreSQLColumnIdentifier]
    public var constraints: [PostgreSQLTableConstraint]
    public var deleteConstraints: [PostgreSQLTableConstraint]
    
    public static func schema(_ statement: Statement, _ table: TableIdentifier) -> FluentPostgreSQLSchema {
        return .init(
            statement: statement,
            table: table,
            columns: [],
            deleteColumns: [],
            constraints: [],
            deleteConstraints: []
        )
    }
}
