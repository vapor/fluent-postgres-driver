import FluentSQL

public final class PostgreSQLSQLSerializer: SQLSerializer {
    /// The current placeholder offset used to create PostgreSQL
    /// placeholders for parameterized queries.
    private var placeholderOffset: Int

    /// Creates a new `PostgreSQLSQLSerializer`
    public init() {
        self.placeholderOffset = 1
    }

    /// See `SQLSerializer.makeEscapedString(from:)`
    public func makeEscapedString(from string: String) -> String {
        return "\"\(string)\""
    }

    /// See `SQLSerializer.makePlaceholder(name:)`
    public func makePlaceholder(name: String) -> String {
        defer { placeholderOffset += 1 }
        return "$\(placeholderOffset)"
    }
}
