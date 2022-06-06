import XCTest
@testable import FluentPostgresDriver

class ConfigurationTests: XCTestCase {
    func testSettingTransactionFlag() {
        let configFactory = DatabaseConfigurationFactory.postgres(configuration: .init(hostname: "hostname", username: "username"), inTransaction: true)
        
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let threadPool = NIOThreadPool(numberOfThreads: System.coreCount)
        let dbs = Databases(threadPool: threadPool, on: eventLoopGroup)
        
        let driver = configFactory.make().makeDriver(for: dbs)
        let postgresDriver = driver as! _FluentPostgresDriver
        XCTAssertTrue(postgresDriver.inTransaction)
        
        let configFactory2 = DatabaseConfigurationFactory.postgres(configuration: .init(hostname: "hostname", username: "username"), inTransaction: false)
        let driver2 = configFactory2.make().makeDriver(for: dbs)
        let postgresDriver2 = driver2 as! _FluentPostgresDriver
        XCTAssertFalse(postgresDriver2.inTransaction)
        
        let configFactory3 = DatabaseConfigurationFactory.postgres(configuration: .init(hostname: "hostname", username: "username"))
        let driver3 = configFactory3.make().makeDriver(for: dbs)
        let postgresDriver3 = driver3 as! _FluentPostgresDriver
        XCTAssertFalse(postgresDriver3.inTransaction)
        
        driver.shutdown()
        driver2.shutdown()
        driver3.shutdown()
        XCTAssertNoThrow(try threadPool.syncShutdownGracefully())
        XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
    }
}
