extension PostgreSQLDatabase: SQLConstraintIdentifierNormalizer {
    /// See `SQLConstraintIdentifierNormalizer`.
    public static func normalizeSQLConstraintIdentifier(_ identifier: String) -> String {
        return identifier
    }
}

extension PostgreSQLDatabase: SchemaSupporting {
    /// See `SchemaSupporting`.
    public typealias Schema = FluentPostgreSQLSchema
    
    /// See `SchemaSupporting`.
    public typealias SchemaAction = FluentPostgreSQLSchemaStatement
    
    /// See `SchemaSupporting`.
    public typealias SchemaField = PostgreSQLColumnDefinition
    
    /// See `SchemaSupporting`.
    public typealias SchemaFieldType = PostgreSQLDataType
    
    /// See `SchemaSupporting`.
    public typealias SchemaConstraint = PostgreSQLTableConstraint
    
    /// See `SchemaSupporting`.
    public typealias SchemaReferenceAction = PostgreSQLConflictResolution
    
    /// See `SchemaSupporting`.
    public static func schemaField(for type: Any.Type, isIdentifier: Bool, _ column: PostgreSQLColumnIdentifier) -> PostgreSQLColumnDefinition {
        var constraints: [PostgreSQLColumnConstraint] = []
        var dataType: PostgreSQLDataType
        
        var type = type
        if let optional = type as? AnyOptionalType.Type {
            type = optional.anyWrappedType
            if isIdentifier {
                constraints.append(.notNull)
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
        
        if let type = type as? PostgreSQLDataTypeStaticRepresentable.Type {
            dataType = type.postgreSQLDataType
        } else {
            dataType = .jsonb
        }
        
        if isIdentifier {
            if _globalEnableIdentityColumns {
                let pkDefault: PostgreSQLPrimaryKeyDefault?
                // create a unique name for the primary key since it will be added
                // as a separate index.
                let unique: String
                if let table = column.table {
                    unique = table.identifier.string + "." + column.identifier.string
                } else {
                    unique = column.identifier.string
                }
                switch dataType {
                case .smallint, .integer, .bigint:
                    pkDefault = .generated(.byDefault)
                default:
                    pkDefault = nil
                }
                constraints.append(.primaryKey(default: pkDefault, identifier: .identifier("pk:\(unique)")))
            } else {
                switch dataType {
                case .smallint: dataType = .smallserial
                case .integer: dataType = .serial
                case .bigint: dataType = .bigserial
                default: break
                }
            }
        }
        
        if isArray {
            dataType = .array(dataType)
        }
        
        // FIXME: is array support
        return .columnDefinition(column, dataType, constraints)
    }
    
    /// See `SchemaSupporting`.
    public static func enableReferences(on connection: PostgreSQLConnection) -> Future<Void> {
        // enabled by default
        return .done(on: connection)
    }
    
    /// See `SchemaSupporting`.
    public static func disableReferences(on connection: PostgreSQLConnection) -> Future<Void> {
        return Future.map(on: connection) {
            throw PostgreSQLError(identifier: "disableReferences", reason: "PostgreSQL does not support disabling foreign key checks.")
        }
    }
}
