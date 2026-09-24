package enum FluentPostgresError: Error, Equatable {
    case invalidURL(String)
    case transactionControlRequiresConnection
}
