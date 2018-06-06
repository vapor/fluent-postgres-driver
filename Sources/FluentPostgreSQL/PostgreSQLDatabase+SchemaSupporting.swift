extension PostgreSQLQuery {
    public struct FluentSchema {
        public enum Statement {
            case create
            case alter
            case drop
        }
        
        public var statement: Statement
        public var table: String
        public var createColumns: [ColumnDefinition]
        public var deleteColumns: [Column]
        public var createConstraints: [TableConstraint]
        public var deleteConstraints: [TableConstraint]
        
        public init(statement: Statement = .create, table: String) {
            self.statement = statement
            self.table = table
            self.createColumns = []
            self.deleteColumns = []
            self.createConstraints = []
            self.deleteConstraints = []
        }
    }
    
    static func fluent(_ fluent: FluentSchema) -> PostgreSQLQuery {
        let query: PostgreSQLQuery
        switch fluent.statement {
        case .create:
            query = .createTable(.init(
                storage: .permanent,
                ifNotExists: false,
                name: fluent.table,
                columns: fluent.createColumns,
                constraints: fluent.createConstraints
            ))
        case .alter: fatalError()
        case .drop:
            query = .dropTable(.init(name: fluent.table, ifExists: false))
        }
        return query
    }
}

extension PostgreSQLDatabase: SchemaSupporting {
    public static var schemaActionCreate: PostgreSQLQuery.FluentSchema.Statement {
        return .create
    }
    
    public static var schemaActionUpdate: PostgreSQLQuery.FluentSchema.Statement {
        return .alter
    }
    
    public static var schemaActionDelete: PostgreSQLQuery.FluentSchema.Statement {
        return .drop
    }
    
    public static func schemaCreate(_ statement: PostgreSQLQuery.FluentSchema.Statement, _ table: String) -> PostgreSQLQuery.FluentSchema {
        return .init(statement: statement, table: table)
    }
    
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ column: PostgreSQLQuery.Column) -> PostgreSQLQuery.ColumnDefinition {
        var constraints: [PostgreSQLQuery.ColumnConstraint] = []
        let dataType: PostgreSQLQuery.DataType
        
        var type = type
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
            if isIdentifier {
                constraints.append(.notNull)
            } else {
                constraints.append(.null)
            }
        } else {
            constraints.append(.notNull)
        }
        
        let isArray: Bool
        if let array = type as? AnyArray.Type {
            type = array.anyElementType
            isArray = true
        } else {
            isArray = false
        }
        
        if let type = type as? PostgreSQLStaticColumnTypeRepresentable.Type {
            dataType = type.postgreSQLColumnType
        } else {
            dataType = .jsonb
        }
        
        if isIdentifier {
            switch dataType {
            case .smallint, .integer, .bigint:
                constraints.append(.init(.generated(.byDefault)))
            default: break
            }
            
            // create a unique name for the primary key since it will be added
            // as a separate index. 
            let unique: String
            if let table = column.table {
                unique = table + "." + column.name
            } else {
                unique = column.name
            }
            constraints.append(.init(.primaryKey, name: "pk:" + unique))
        }
        
        return .init(name: column.name, dataType: dataType, isArray: isArray, constraints: constraints)
    }
    
    public static func schemaField(_ column: PostgreSQLQuery.Column, _ dataType: PostgreSQLQuery.DataType) -> PostgreSQLQuery.ColumnDefinition {
        return .init(name: column.name, dataType: dataType)
    }
    
    public static func schemaFieldCreate(_ field: PostgreSQLQuery.ColumnDefinition, to query: inout PostgreSQLQuery.FluentSchema) {
        query.createColumns.append(field)
    }
    
    public static func schemaFieldDelete(_ field: PostgreSQLQuery.Column, to query: inout PostgreSQLQuery.FluentSchema) {
        query.deleteColumns.append(field)
    }
    
    public static func schemaReference(from: PostgreSQLQuery.Column, to: PostgreSQLQuery.Column, onUpdate: PostgreSQLQuery.ForeignKeyAction?, onDelete: PostgreSQLQuery.ForeignKeyAction?) -> PostgreSQLQuery.TableConstraint {
        return .init(.foreignKey(.init(
            columns: [from.name],
            foreignTable: to.table!,
            foreignColumns: [to.name],
            onDelete: onDelete,
            onUpdate: onUpdate
        )), as: "fk:" + from.name + "+" + to.table! + "." + to.name)
    }
    
    public static func schemaUnique(on columns: [PostgreSQLQuery.Column]) -> PostgreSQLQuery.TableConstraint {
        let names = columns.map { $0.name }
        let uid = names.joined(separator: "+")
        return .init(.unique(.init(
            columns: names
        )), as: "uq:" + uid)
    }
    
    public static func schemaConstraintCreate(_ constraint: PostgreSQLQuery.TableConstraint, to query: inout PostgreSQLQuery.FluentSchema) {
        query.createConstraints.append(constraint)
    }
    
    public static func schemaConstraintDelete(_ constraint: PostgreSQLQuery.TableConstraint, to query: inout PostgreSQLQuery.FluentSchema) {
        query.deleteConstraints.append(constraint)
    }
    
    public typealias Schema = PostgreSQLQuery.FluentSchema
    
    public typealias SchemaAction = PostgreSQLQuery.FluentSchema.Statement
    
    public typealias SchemaField = PostgreSQLQuery.ColumnDefinition
    
    public typealias SchemaFieldType = PostgreSQLQuery.DataType
    
    public typealias SchemaConstraint = PostgreSQLQuery.TableConstraint
    
    public typealias SchemaReferenceAction = PostgreSQLQuery.ForeignKeyAction
}
