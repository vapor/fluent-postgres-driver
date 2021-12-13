import FluentSQL

extension PostgresError: DatabaseError {
    public var isSyntaxError: Bool {
        switch self.code {
        case .syntaxErrorOrAccessRuleViolation,
             .syntaxError,
             .insufficientPrivilege,
             .cannotCoerce,
             .groupingError,
             .windowingError,
             .invalidRecursion,
             .invalidForeignKey,
             .invalidName,
             .nameTooLong,
             .reservedName,
             .datatypeMismatch,
             .indeterminateDatatype,
             .collationMismatch,
             .indeterminateCollation,
             .wrongObjectType,
             .undefinedColumn,
             .undefinedFunction,
             .undefinedTable,
             .undefinedParameter,
             .undefinedObject,
             .duplicateColumn,
             .duplicateCursor,
             .duplicateDatabase,
             .duplicateFunction,
             .duplicatePreparedStatement,
             .duplicateSchema,
             .duplicateTable,
             .duplicateAlias,
             .duplicateObject,
             .ambiguousColumn,
             .ambiguousFunction,
             .ambiguousParameter,
             .ambiguousAlias,
             .invalidColumnReference,
             .invalidColumnDefinition,
             .invalidCursorDefinition,
             .invalidDatabaseDefinition,
             .invalidFunctionDefinition,
             .invalidPreparedStatementDefinition,
             .invalidSchemaDefinition,
             .invalidTableDefinition,
             .invalidObjectDefinition:
            return true
        default:
            return false
        }
    }
    
    public var isConnectionClosed: Bool {
        switch self {
        case .connectionClosed:
            return true
        default:
            return false
        }
    }
    
    public var isConstraintFailure: Bool {
        switch self.code {
        case .integrityConstraintViolation,
             .restrictViolation,
             .notNullViolation,
             .foreignKeyViolation,
             .uniqueViolation,
             .checkViolation,
             .exclusionViolation:
            return true
        default:
            return false
        }
    }
}
