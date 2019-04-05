#if !canImport(ObjectiveC)
import XCTest

extension FluentPostgresDriverTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FluentPostgresDriverTests = [
        ("testAggregates", testAggregates),
        ("testAll", testAll),
        ("testBatchCreate", testBatchCreate),
        ("testBatchUpdate", testBatchUpdate),
        ("testChunkedFetch", testChunkedFetch),
        ("testCreate", testCreate),
        ("testDelete", testDelete),
        ("testEagerLoadChildren", testEagerLoadChildren),
        ("testEagerLoadJoinJSONEncode", testEagerLoadJoinJSONEncode),
        ("testEagerLoadParent", testEagerLoadParent),
        ("testEagerLoadParentJoin", testEagerLoadParentJoin),
        ("testEagerLoadSubqueryJSONEncode", testEagerLoadSubqueryJSONEncode),
        ("testIdentifierGeneration", testIdentifierGeneration),
        ("testJoin", testJoin),
        ("testMigrator", testMigrator),
        ("testMigratorError", testMigratorError),
        ("testNestedModel", testNestedModel),
        ("testNullifyField", testNullifyField),
        ("testRead", testRead),
        ("testUniqueFields", testUniqueFields),
        ("testUpdate", testUpdate),
    ]
}

extension PostgresKitTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__PostgresKitTests = [
        ("testPerformance", testPerformance),
        ("testSQLKitBenchmark", testSQLKitBenchmark),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FluentPostgresDriverTests.__allTests__FluentPostgresDriverTests),
        testCase(PostgresKitTests.__allTests__PostgresKitTests),
    ]
}
#endif
