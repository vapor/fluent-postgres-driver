import FluentSQL

internal class PostgreSQLSQLSerializer: SQLSerializer {
    /// See `SQLSerializer.makeEscapedString(from:)`
    func makeEscapedString(from string: String) -> String {
        return "\"\(string)\""
    }
}
