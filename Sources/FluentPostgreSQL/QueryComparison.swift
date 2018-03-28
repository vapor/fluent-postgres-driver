// PostgreSQL has iLike and it is the operator ~~* in the SQL
fileprivate let ilike = DataPredicateComparison.sql("ilike")

// Case Insensitive containment
infix operator ~=*
/// Has prefix
public func ~=* <Model, Value>(lhs: KeyPath<Model, Value>, rhs: String) throws -> ModelFilter<Model>
    where Model.Database.QueryFilter: DataPredicateComparisonConvertible
{
    return try _contains(lhs, ilike, .data("%\(rhs)"))
}

infix operator =~*
/// Has suffix.
public func =~* <Model, Value>(lhs: KeyPath<Model, Value>, rhs: String) throws -> ModelFilter<Model>
    where Model.Database.QueryFilter: DataPredicateComparisonConvertible
{
    return try _contains(lhs, ilike, .data("\(rhs)%"))
}

infix operator ~~*
/// Contains.
public func ~~* <Model, Value>(lhs: KeyPath<Model, Value>, rhs: String) throws -> ModelFilter<Model>
    where Model.Database.QueryFilter: DataPredicateComparisonConvertible
{
    return try _contains(lhs, ilike, .data("%\(rhs)%"))
}

/// Operator helper func.
private func _contains<M, V>(_ key: KeyPath<M, V>, _ comp: DataPredicateComparison, _ value: QueryFilterValue<M.Database>) throws -> ModelFilter<M>
    where M.Database.QueryFilter: DataPredicateComparisonConvertible
{
    let filter = try QueryFilter<M.Database>(
        field: key.makeQueryField(),
        type: .custom(.convertFromDataPredicateComparison(comp)),
        value: value
    )
    return ModelFilter<M>(filter: filter)
}
