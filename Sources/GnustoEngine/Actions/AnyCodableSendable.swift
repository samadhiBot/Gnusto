import Foundation

/// A type-erased wrapper for `Codable & Sendable` values that enables JSON encoding/decoding.
///
/// This wrapper allows `StateValue` to store arbitrary codable types while maintaining
/// type safety through casting methods and proper JSON serialization support.
public struct AnyCodableSendable: Codable, Sendable, Hashable {
    private let data: Data
    let typeName: String

    /// Creates an `AnyCodableSendable` wrapper around any `Codable & Sendable` value.
    /// - Parameter value: The value to wrap, which must conform to `Codable & Sendable`.
    public init<T: Codable & Sendable>(_ value: T) throws {
        self.data = try JSONEncoder().encode(value)
        self.typeName = String(describing: T.self)
    }

    /// Attempts to decode the wrapped value as the specified type.
    /// - Parameter type: The type to decode as (must be `Codable & Sendable`).
    /// - Returns: The decoded value of the specified type, or `nil` if decoding fails.
    public func decode<T: Codable & Sendable>(as type: T.Type) throws -> T {
        return try JSONDecoder().decode(type, from: data)
    }

    /// Attempts to decode the wrapped value as the specified type, returning nil on failure.
    /// - Parameter type: The type to decode as (must be `Codable & Sendable`).
    /// - Returns: The decoded value of the specified type, or `nil` if decoding fails.
    public func tryDecode<T: Codable & Sendable>(as type: T.Type) -> T? {
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Codable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(typeName, forKey: .typeName)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(Data.self, forKey: .data)
        self.typeName = try container.decode(String.self, forKey: .typeName)
    }

    private enum CodingKeys: String, CodingKey {
        case data
        case typeName
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(typeName)
    }

    public static func == (lhs: AnyCodableSendable, rhs: AnyCodableSendable) -> Bool {
        lhs.data == rhs.data && lhs.typeName == rhs.typeName
    }
}
