import FluentSQL

struct PostgresConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .uint8:
            return SQLRaw(#""char""#)
        case .uuid:
            return SQLRaw("UUID")
        case .bool:
            return SQLRaw("BOOL")
        case .data:
            return SQLRaw("BYTEA")
        case .datetime:
            return SQLRaw("TIMESTAMPTZ")
        case .double:
            return SQLRaw("DOUBLE PRECISION")
        case .json:
            return SQLRaw("JSONB")
        case .enum(let value):
            return SQLIdentifier(value.name)
        default:
            return nil
        }
    }

    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        switch path.count {
        case 1:
            return SQLRaw("\(column)->>'\(path[0])'")
        case 2...:
            let inner = path[0..<path.count - 1].map { "'\($0)'" }.joined(separator: "->")
            return SQLRaw("\(column)->\(inner)->>'\(path.last!)'")
        default:
            fatalError()
        }
    }
}
