public enum PostgreSQLSchemaAction {
    case create
    case alter
    case drop
}

extension PostgreSQLDatabase: SchemaSupporting {
    public static var schemaActionCreate: PostgreSQLSchemaAction {
        return .create
    }
    
    public static var schemaActionUpdate: PostgreSQLSchemaAction {
        return .alter
    }
    
    public static var schemaActionDelete: PostgreSQLSchemaAction {
        return .drop
    }
    
    public static func schemaCreate(_ action: PostgreSQLSchemaAction, _ entity: String) -> PostgreSQLQuery.DDL {
        switch action {
        case .create: return .createTable(.init(name: entity))
        case .alter:
            #warning("add alter schema action")
            return .dropTable(.init(name: entity))
        case .drop: return .dropTable(.init(name: entity))
        }
    }
    
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ column: PostgreSQLQuery.Column) -> PostgreSQLQuery.DDL.ColumnDefinition {
        var constraints: [PostgreSQLQuery.DDL.ColumnDefinition.Constraint] = []
        let dataType: PostgreSQLQuery.DDL.ColumnDefinition.DataType
        
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
            case .smallint, .integer, .bigint: constraints.append(.generated(.byDefault))
            default: break
            }
            constraints.append(.primaryKey)
        }
        
        return .init(name: column.name, dataType: dataType, isArray: isArray, constraints: constraints)
    }
    
    public static func schemaField(_ column: PostgreSQLQuery.Column, _ dataType: PostgreSQLQuery.DDL.ColumnDefinition.DataType) -> PostgreSQLQuery.DDL.ColumnDefinition {
        return PostgreSQLQuery.DDL.ColumnDefinition.init(name: column.name, dataType: dataType)
    }
    
    public static func schemaFieldCreate(_ field: PostgreSQLQuery.DDL.ColumnDefinition, to query: inout PostgreSQLQuery.DDL) {
        #warning("supporting deleting fields")
        switch query {
        case .createTable(var create):
            create.items.append(.columnDefinition(field))
            query = .createTable(create)
        default: break
        }
    }
    
    public static func schemaFieldDelete(_ field: PostgreSQLQuery.Column, to query: inout PostgreSQLQuery.DDL) {
        #warning("supporting deleting fields")
        switch query {
        case .createTable: break
        default: break
        }
    }
    
    public static func schemaReference(from: PostgreSQLQuery.Column, to: PostgreSQLQuery.Column, onUpdate: PostgreSQLQuery.DDL.ForeignKeyAction?, onDelete: PostgreSQLQuery.DDL.ForeignKeyAction?) -> PostgreSQLQuery.DDL.Constraint {
        return .init(.foreignKey(
            columns: [from.name],
            reftable: to.table!,
            refcolumns: [to.name],
            onDelete: onDelete,
            onUpdate: onUpdate
        ), as: "fk:" + from.name + "+" + to.table! + "." + to.name)
    }
    
    public static func schemaUnique(on columns: [PostgreSQLQuery.Column]) -> PostgreSQLQuery.DDL.Constraint {
        let names = columns.map { $0.name }
        let uid = names.joined(separator: "+")
        return .init(.unique(
            columns: names, nil
        ), as: "uq:" + uid)
    }
    
    public static func schemaConstraintCreate(_ constraint: PostgreSQLQuery.DDL.Constraint, to query: inout PostgreSQLQuery.DDL) {
        switch query {
        case .createTable(var create):
            create.items.append(.tableConstraint(constraint))
            query = .createTable(create)
        default: break
        }
    }
    
    public static func schemaConstraintDelete(_ constraint: PostgreSQLQuery.DDL.Constraint, to query: inout PostgreSQLQuery.DDL) {
        #warning("supporting deleting constraints")
        switch query {
        case .createTable: break
        default: break
        }
    }
    
    public typealias Schema = PostgreSQLQuery.DDL
    
    public typealias SchemaAction = PostgreSQLSchemaAction
    
    public typealias SchemaField = PostgreSQLQuery.DDL.ColumnDefinition
    
    public typealias SchemaFieldType = PostgreSQLQuery.DDL.ColumnDefinition.DataType
    
    public typealias SchemaConstraint = PostgreSQLQuery.DDL.Constraint
    
    public typealias SchemaReferenceAction = PostgreSQLQuery.DDL.ForeignKeyAction
    
    
}
