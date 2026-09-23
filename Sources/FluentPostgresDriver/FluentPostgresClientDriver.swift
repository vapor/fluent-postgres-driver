import FluentKit
import Logging
import PostgresNIO
import ServiceLifecycle

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
final class _FluentPostgresClientDriver<E: PostgresJSONEncoder, D: PostgresJSONDecoder>: DatabaseDriver {
    let client: PostgresClient
    
    let group: ServiceGroup
    // To track service group shutdown
    let runFinished: EventLoopFuture<Void>

    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let sqlLogLevel: Logger.Level

    init(
        client: PostgresClient,
        eventLoopGroup: some EventLoopGroup,
        encodingContext: PostgresEncodingContext<E>, 
        decodingContext: PostgresDecodingContext<D>,
        sqlLogLevel: Logger.Level,
        logger: Logger
    ) {
        var config = ServiceGroupConfiguration(services: [client], logger: logger)
        config.maximumGracefulShutdownDuration = .seconds(10)
        let group = ServiceGroup(configuration: config)
        let finished = eventLoopGroup.any().makePromise(of: Void.self)

        self.group = group
        self.runFinished = finished.futureResult
        self.client = client
        self.encodingContext = encodingContext
        self.decodingContext = decodingContext
        self.sqlLogLevel = sqlLogLevel

        Task.detached {
            do {
                try await group.run()
            } catch {
                logger.error("Error running PostgresClient ServiceGroup \(error)")
            }
            finished.succeed()
        }
    }

    func makeDatabase(with context: DatabaseContext) -> any Database {
        _FluentPostgresClientDatabase(
            source: .client(client),
            context: context, 
            encodingContext: self.encodingContext,
            decodingContext: self.decodingContext,
            inTransaction: false,
            sqlLogLevel: sqlLogLevel
        )
    }

    // Should be called off loop
    func shutdown() {
        Task.detached { await self.group.triggerGracefulShutdown() }
        try? self.runFinished.wait()
    }

    func shutdownAsync() async {
        await self.group.triggerGracefulShutdown()
        try? await self.runFinished.get()
    }
}
