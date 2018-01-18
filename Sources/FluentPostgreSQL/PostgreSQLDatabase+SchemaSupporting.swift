import Async
import Foundation

/// Adds ability to create, update, and delete schemas using a `PostgreSQLDatabase`.
extension PostgreSQLDatabase: SchemaSupporting {
    /// See `SchemaSupporting.dataType`
    public static func dataType(for field: SchemaField<PostgreSQLDatabase>) -> String {
        var string: String
        switch field.type.type {
        case .bool: string = "boolean"
        case .bytea: string = "bytea"
        case .char: string = "char"
        case .int8: string = "bitint"
        case .int2: string = "smallint"
        case .int4, .oid, .regproc: string = "int"
        case .text, .name: string = "text"
        case .point: string = "point"
        case .float4: string = "real"
        case .float8: string = "double precision"
        case ._aclitem: string = "_aclitem"
        case .bpchar: string = "bpchar"
        case .varchar: string = "varchar"
        case .date: string = "date"
        case .time: string = "time"
        case .timestamp: string = "timestamp"
        case .numeric: string = "numeric"
        case .void: string = "void"
        case .pg_node_tree: string = "pg_node_tree"
        }

        if field.type.size >= 0 {
            string += "(\(field.type.size))"
        }

        if field.isIdentifier {
            string += " primary key"
        }

        if !field.isOptional {
            string += " not null"
        }

        return string
    }

    /// See `SchemaSupporting.fieldType`
    public static func fieldType(for type: Any.Type) throws -> PostgreSQLColumn {
        if let representable = type as? PostgreSQLColumnStaticRepresentable.Type {
            return representable.postgreSQLColumn
        } else {
            throw PostgreSQLError(
                identifier: "fieldType",
                reason: "No PostgreSQL column type known for \(type).",
                suggestedFixes: [
                    "Conform \(type) to `PostgreSQLColumnStaticRepresentable` to specify field type or implement a custom migration.",
                    "Specify the `PostgreSQLColumn` manually using the schema builder in a migration."
                ]
            )
        }
    }

    /// See `SchemaSupporting.execute`
    public static func execute(schema: DatabaseSchema<PostgreSQLDatabase>, on connection: PostgreSQLConnection) -> Future<Void> {
        do {
            let sqlQuery = schema.makeSchemaQuery()
            let sqlString = PostgreSQLSQLSerializer().serialize(schema: sqlQuery)
            return try connection.query(sqlString).map(to: Void.self) { rows in
                assert(rows.count == 0)
            }
        } catch {
            return Future(error: error)
        }
    }
}
