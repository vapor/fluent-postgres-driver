import FluentSQL

public final class PostgreSQLSQLSerializer: SQLSerializer {
    /// The current placeholder offset used to create PostgreSQL
    /// placeholders for parameterized queries.
    var placeholderOffset: Int

    /// Creates a new `PostgreSQLSQLSerializer`
    init() {
        self.placeholderOffset = 1
    }

    /// See `SQLSerializer.makeEscapedString(from:)`
    func makeEscapedString(from string: String) -> String {
        return "\"\(string)\""
    }

    /// See `SQLSerializer.makePlaceholder(name:)`
    func makePlaceholder(name: String) -> String {
        defer { placeholderOffset += 1 }
        return "$\(placeholderOffset)"
    }
}
