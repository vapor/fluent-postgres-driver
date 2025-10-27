import FluentKit
import FluentSQL
import PostgresKit
import PostgresNIO

extension PostgresError.Code {
    fileprivate var isSyntaxError: Bool {
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
            true
        default:
            false
        }
    }

    fileprivate var isConstraintFailure: Bool {
        switch self {
        case .integrityConstraintViolation,
            .restrictViolation,
            .notNullViolation,
            .foreignKeyViolation,
            .uniqueViolation,
            .checkViolation,
            .exclusionViolation:
            true
        default:
            false
        }
    }
}

// Used for DatabaseError conformance
extension PostgresError {
    public var isSyntaxError: Bool { self.code.isSyntaxError }
    public var isConnectionClosed: Bool {
        switch self {
        case .connectionClosed: true
        default: false
        }
    }
    public var isConstraintFailure: Bool { self.code.isConstraintFailure }
}

// Used for DatabaseError conformance
extension PSQLError {
    public var isSyntaxError: Bool {
        switch self.code {
        case .server: self.serverInfo?[.sqlState].map { PostgresError.Code(raw: $0).isSyntaxError } ?? false
        default: false
        }
    }

    public var isConnectionClosed: Bool {
        switch self.code {
        case .serverClosedConnection, .clientClosedConnection: true
        default: false
        }
    }

    public var isConstraintFailure: Bool {
        switch self.code {
        case .server: self.serverInfo?[.sqlState].map { PostgresError.Code(raw: $0).isConstraintFailure } ?? false
        default: false
        }
    }
}

extension PostgresError: @retroactive DatabaseError {}
extension PSQLError: @retroactive DatabaseError {}
