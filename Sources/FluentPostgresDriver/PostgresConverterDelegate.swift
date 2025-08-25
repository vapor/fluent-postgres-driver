import FluentKit
import FluentSQL
import SQLKit

struct PostgresConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> (any SQLExpression)? {
        switch dataType {
        case .uuid:
            SQLRaw("UUID")
        case .bool:
            SQLRaw("BOOL")
        case .data:
            SQLRaw("BYTEA")
        case .date:
            SQLRaw("DATE")
        case .datetime:
            SQLRaw("TIMESTAMPTZ")
        case .double:
            SQLRaw("DOUBLE PRECISION")
        case .dictionary:
            SQLRaw("JSONB")
        case .array(of: let type):
            if let type, let dataType = self.customDataType(type) {
                SQLArrayDataType(dataType: dataType)
            } else {
                SQLRaw("JSONB")
            }
        case .enum(let value):
            SQLIdentifier(value.name)
        case .int8, .uint8:
            SQLIdentifier("char")
        case .int16, .uint16:
            SQLRaw("SMALLINT")
        case .int32, .uint32:
            SQLRaw("INT")
        case .int64, .uint64:
            SQLRaw("BIGINT")
        case .string:
            SQLRaw("TEXT")
        case .time:
            SQLRaw("TIME")
        case .float:
            SQLRaw("FLOAT")
        case .custom:
            nil
        }
    }
}

private struct SQLArrayDataType: SQLExpression {
    let dataType: any SQLExpression

    func serialize(to serializer: inout SQLSerializer) {
        self.dataType.serialize(to: &serializer)
        serializer.write("[]")
    }
}
