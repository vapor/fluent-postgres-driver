extension PostgreSQLDatabase: JoinSupporting {
    /// See `SQLDatabase`.
    public typealias QueryJoin = PostgreSQLJoin
    
    /// See `SQLDatabase`.
    public typealias QueryJoinMethod = PostgreSQLJoinMethod
}
