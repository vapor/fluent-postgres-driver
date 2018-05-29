import FluentSQL

internal class PostgreSQLSQLSerializer: SQLSerializer {
    /// The current placeholder offset used to create PostgreSQL
    /// placeholders for parameterized queries.
    var placeholderOffset: Int

    /// Creates a new `PostgreSQLSQLSerializer`
    init() {
        self.placeholderOffset = 1
    }

    /// See `SQLSerializer`
    func makeEscapedString(from string: String) -> String {
        return "\"" + string + "\""
    }

    /// See `SQLSerializer`
    func makePlaceholder() -> String {
        defer { placeholderOffset += 1 }
        return "$" + String(describing: placeholderOffset)
    }
}
