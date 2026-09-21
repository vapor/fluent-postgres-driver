enum FluentPostgresError: Error {
    case invalidURL(String)
    case transactionControlRequiresConnection
}
