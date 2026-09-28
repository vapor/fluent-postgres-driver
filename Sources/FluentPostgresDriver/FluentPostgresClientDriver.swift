import FluentKit
import Logging
import PostgresNIO
import ServiceLifecycle

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
final class _FluentPostgresClientDriver<E: PostgresJSONEncoder, D: PostgresJSONDecoder>: DatabaseDriver {
    enum Lifecycle {
        /// The driver created the client and runs it in a private ServiceGroup.
        case owned(group: ServiceGroup, runFinished: EventLoopFuture<Void>)
        /// The user runs the client elsewhere; the driver only borrows it.
        case external
    }

    let client: PostgresClient
    let lifecycle: Lifecycle

    let encodingContext: PostgresEncodingContext<E>
    let decodingContext: PostgresDecodingContext<D>
    let sqlLogLevel: Logger.Level

    init(
        client: PostgresClient,
        encodingContext: PostgresEncodingContext<E>, 
        decodingContext: PostgresDecodingContext<D>,
        sqlLogLevel: Logger.Level,
        logger: Logger
    ) {
        self.client = client
        self.lifecycle = .external
        self.encodingContext = encodingContext
        self.decodingContext = decodingContext
        self.sqlLogLevel = sqlLogLevel
    }

    init(
        configuration: PostgresClient.Configuration,
        eventLoopGroup: some EventLoopGroup,
        encodingContext: PostgresEncodingContext<E>, 
        decodingContext: PostgresDecodingContext<D>,
        sqlLogLevel: Logger.Level,
        logger: Logger
    ) {
        let client = PostgresClient(configuration: configuration)
        var config = ServiceGroupConfiguration(services: [client], logger: logger)
        config.maximumGracefulShutdownDuration = .seconds(10)
        let group = ServiceGroup(configuration: config)
        let finished = eventLoopGroup.any().makePromise(of: Void.self)

        self.lifecycle = .owned(group: group, runFinished: finished.futureResult)

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
        guard case .owned(let group, let finished) = self.lifecycle else { return }
        Task.detached { await group.triggerGracefulShutdown() }
        try? finished.wait()
    }

    func shutdownAsync() async {
        guard case .owned(let group, let finished) = self.lifecycle else { return }
        await group.triggerGracefulShutdown()
        try? await finished.get()
    }
}
