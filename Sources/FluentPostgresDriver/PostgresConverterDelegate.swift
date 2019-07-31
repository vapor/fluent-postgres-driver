import FluentSQL

struct PostgresConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> SQLExpression? {
        switch dataType {
        case .uuid:
            return SQLRaw("UUID")
        case .bool:
            return SQLRaw("BOOL")
        case .data:
            return SQLRaw("BYTEA")
        case .datetime:
            return SQLRaw("TIMESTAMPTZ")
        default:
            return nil
        }
    }

    func nestedFieldExpression(_ column: String, _ path: [String]) -> SQLExpression {
        return SQLRaw("\(column)->>'\(path[0])'")
    }
}
