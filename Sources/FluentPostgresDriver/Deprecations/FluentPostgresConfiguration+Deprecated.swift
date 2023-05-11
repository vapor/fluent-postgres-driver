import Logging
import FluentKit
import AsyncKit
import NIOCore
import NIOSSL
import Foundation
import PostgresKit
import PostgresNIO

// N.B.: This excessive method duplication is required to maintain the original public API, which allowed defaulting
// either the encoder, decoder, or both. The "defaulting both" versions now forward to the new API, the others are here.

// Factory methods accepting both encoder and decoder
extension DatabaseConfigurationFactory {
    enum FluentPostgresError: Error {
        case invalidURL(String)
    }

    @available(*, deprecated, message: "Use `.postgres(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        url: String, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder, decoder: PostgresDataDecoder, sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        guard let configuration = PostgresConfiguration(url: url) else { throw FluentPostgresError.invalidURL(url) }
        return .postgres(configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder, decoder: decoder, sqlLogLevel: sqlLogLevel
        )
    }

    @available(*, deprecated, message: "Use `.postgres(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        url: URL, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder, decoder: PostgresDataDecoder, sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        guard let configuration = PostgresConfiguration(url: url) else { throw FluentPostgresError.invalidURL(url.absoluteString) }
        return .postgres( configuration: configuration,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder, decoder: decoder, sqlLogLevel: sqlLogLevel
        )
    }

    @available(*, deprecated, message: "Use `.postgres(configuration:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        hostname: String, port: Int = PostgresConfiguration.ianaPortNumber,
        username: String, password: String, database: String? = nil, tlsConfiguration: TLSConfiguration? = nil,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        .postgres(configuration: .init(
            hostname: hostname, port: port, username: username, password: password, database: database, tlsConfiguration: tlsConfiguration),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder, decoder: decoder, sqlLogLevel: sqlLogLevel
        )
    }

    @available(*, deprecated, message: "Use `.postgres(configuration:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        configuration: PostgresConfiguration,
        maxConnectionsPerEventLoop: Int = 1,
        connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder = .init(),
        decoder: PostgresDataDecoder = .init(),
        sqlLogLevel: Logger.Level = .debug
    ) -> DatabaseConfigurationFactory {
        .postgres(
            configuration: .init(legacyConfiguration: configuration),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encodingContext: .init(jsonEncoder: TypeErasedPostgresJSONEncoder(json: encoder.json)),
            decodingContext: .init(jsonDecoder: TypeErasedPostgresJSONDecoder(json: decoder.json)),
            sqlLogLevel: sqlLogLevel
        )
    }
}

// Factory methods accepting only encoder or only decoder.
extension DatabaseConfigurationFactory {
    @available(*, deprecated, message: "Use `.postgres(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        url: String, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder, sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        try .postgres(url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder, decoder: .init(), sqlLogLevel: sqlLogLevel
        )
    }

    @available(*, deprecated, message: "Use `.postgres(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        url: String, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        decoder: PostgresDataDecoder, sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        try .postgres(url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: .init(), decoder: decoder, sqlLogLevel: sqlLogLevel
        )
    }

    @available(*, deprecated, message: "Use `.postgres(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        url: URL, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        encoder: PostgresDataEncoder, sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        try .postgres(url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: encoder, decoder: .init(), sqlLogLevel: sqlLogLevel
        )
    }

    @available(*, deprecated, message: "Use `.postgres(url:maxConnectionsPerEventLoop:connectionPoolTimeout:encodingContext:decodingContext:sqlLogLevel:)` instead.")
    public static func postgres(
        url: URL, maxConnectionsPerEventLoop: Int = 1, connectionPoolTimeout: TimeAmount = .seconds(10),
        decoder: PostgresDataDecoder, sqlLogLevel: Logger.Level = .debug
    ) throws -> DatabaseConfigurationFactory {
        try .postgres(url: url,
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop, connectionPoolTimeout: connectionPoolTimeout,
            encoder: .init(), decoder: decoder, sqlLogLevel: sqlLogLevel
        )
    }
}

// N.B.: If you change something in these two types, update the copies in PostgresKit too.
fileprivate struct TypeErasedPostgresJSONDecoder: PostgresJSONDecoder {
    let json: any PostgresJSONDecoder
    func decode<T: Decodable>(_: T.Type, from: Data) throws -> T { try self.json.decode(T.self, from: from) }
    func decode<T: Decodable>(_: T.Type, from: ByteBuffer) throws -> T { try self.json.decode(T.self, from: from) }
}

fileprivate struct TypeErasedPostgresJSONEncoder: PostgresJSONEncoder {
    let json: any PostgresJSONEncoder
    func encode<T: Encodable>(_ value: T) throws -> Data { try self.json.encode(value) }
    func encode<T: Encodable>(_ value: T, into: inout ByteBuffer) throws { try self.json.encode(value, into: &into) }
}
