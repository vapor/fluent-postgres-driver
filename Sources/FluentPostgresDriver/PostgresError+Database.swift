import FluentKit
import FluentSQL
import PostgresKit
import PostgresNIO

fileprivate extension PostgresError.Code {
    var isSyntaxError: Bool {
        switch self {
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

    var isConstraintFailure: Bool {
        switch self {
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

// Used for DatabaseError conformance
extension PostgresError {
    public var isSyntaxError: Bool { self.code.isSyntaxError }
    public var isConnectionClosed: Bool {
        switch self {
        case .connectionClosed: return true
        default: return false
        }
    }
    public var isConstraintFailure: Bool { self.code.isConstraintFailure }
}

// Used for DatabaseError conformance
extension PSQLError {
    public var isSyntaxError: Bool {
        switch self.code {
        case .server: return self.serverInfo?[.sqlState].map { PostgresError.Code(raw: $0).isSyntaxError } ?? false
        default: return false
        }
    }
    
    public var isConnectionClosed: Bool {
        switch self.code {
        case .serverClosedConnection, .clientClosedConnection: return true
        default: return false
        }
    }
    
    public var isConstraintFailure: Bool {
        switch self.code {
        case .server: return self.serverInfo?[.sqlState].map { PostgresError.Code(raw: $0).isConstraintFailure } ?? false
        default: return false
        }
    }
}

#if compiler(<6)
extension PostgresError: DatabaseError { }
extension PSQLError: DatabaseError { }
#else
extension PostgresError: @retroactive DatabaseError { }
extension PSQLError: @retroactive DatabaseError { }
#endif
