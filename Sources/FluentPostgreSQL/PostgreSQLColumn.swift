import Foundation

/// A PostgreSQL column type and size.
public struct PostgreSQLColumn {
    /// The columns data type.
    public let type: PostgreSQLDataType

    /// The columns size. Negative values mean varying size.
    public let size: Int16

    /// Creates a new `PostgreSQLColumn`.
    public init(type: PostgreSQLDataType, size: Int16? = nil) {
        self.type = type
        self.size = size ?? -1
    }
}

/// MARK: Representable

/// Capable of being represented statically by a `PostgreSQLColumn`
public protocol PostgreSQLColumnStaticRepresentable {
    /// The `PostgreSQLColumn` type that best represents this type.
    static var postgreSQLColumn: PostgreSQLColumn { get }
}

/// MARK: Default Implementations

extension Data: PostgreSQLColumnStaticRepresentable {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn { return .init(type: .bytea) }
}

extension UUID: PostgreSQLColumnStaticRepresentable {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn { return .init(type: .bytea, size: 16) }
}

extension Date: PostgreSQLColumnStaticRepresentable {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn { return .init(type: .timestamp) }
}

extension FixedWidthInteger {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn {
        switch bitWidth {
        case 64: return .init(type: .int8)
        case 32: return .init(type: .int4)
        case 16: return .init(type: .int2)
        case 8: return .init(type: .char)
        default: fatalError("Unexpected \(Self.self) bit width: \(bitWidth)")
        }
    }
}

extension Int: PostgreSQLColumnStaticRepresentable { }
extension Int8: PostgreSQLColumnStaticRepresentable { }
extension Int16: PostgreSQLColumnStaticRepresentable { }
extension Int32: PostgreSQLColumnStaticRepresentable { }
extension Int64: PostgreSQLColumnStaticRepresentable { }
extension UInt: PostgreSQLColumnStaticRepresentable { }
extension UInt8: PostgreSQLColumnStaticRepresentable { }
extension UInt16: PostgreSQLColumnStaticRepresentable { }
extension UInt32: PostgreSQLColumnStaticRepresentable { }
extension UInt64: PostgreSQLColumnStaticRepresentable { }

extension BinaryFloatingPoint {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn {
        switch exponentBitCount + significandBitCount + 1 {
        case 64: return .init(type: .float8)
        case 32: return .init(type: .float4)
        default: fatalError("Unexpected \(Self.self) bit width: \(exponentBitCount + significandBitCount + 1)")
        }
    }
}

extension Float: PostgreSQLColumnStaticRepresentable { }
extension Double: PostgreSQLColumnStaticRepresentable { }

extension String: PostgreSQLColumnStaticRepresentable {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn { return .init(type: .text) }
}

extension Bool: PostgreSQLColumnStaticRepresentable {
    /// See `PostgreSQLColumnStaticRepresentable.postgreSQLColumn`
    public static var postgreSQLColumn: PostgreSQLColumn { return .init(type: .bool) }
}
