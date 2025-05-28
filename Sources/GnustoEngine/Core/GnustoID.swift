import Foundation

/// A protocol that defines the common interface and behavior for all identifier types
/// in the Gnusto Interactive Fiction Engine.
///
/// `GnustoID` provides default implementations for the most common protocol conformances
/// used by identifier types throughout the engine, including `RawRepresentable`,
/// `Hashable`, `Comparable`, `Codable`, `ExpressibleByStringLiteral`, and `Sendable`.
///
/// This protocol eliminates code duplication across ID types like `ItemID`, `LocationID`,
/// `VerbID`, `DaemonID`, `FuseID`, `GlobalID`, `AttributeID`, and `ContextID`.
///
/// ## Usage
///
/// To create a new ID type, simply declare a struct that conforms to `GnustoID`:
///
/// ```swift
/// public struct MyCustomID: GnustoID {
///     public let rawValue: String
///     
///     public init(rawValue: String) {
///         assert(!rawValue.isEmpty, "MyCustom ID cannot be empty")
///         self.rawValue = rawValue
///     }
/// }
/// ```
///
/// The protocol automatically provides implementations for:
/// - `RawRepresentable` conformance
/// - `Hashable` and `Comparable` based on `rawValue`
/// - `Codable` with plain string encoding/decoding
/// - `ExpressibleByStringLiteral` for convenient initialization
/// - `Sendable` for concurrency safety
/// - Convenience initializer `init(_:)`
public protocol GnustoID: Codable,
                          Comparable,
                          CustomStringConvertible,
                          ExpressibleByStringLiteral,
                          Hashable,
                          RawRepresentable,
                          Sendable where RawValue == String {
    /// The underlying string value of the identifier.
    var rawValue: String { get }
    
    /// Initializes the ID with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    init(rawValue: String)
}

// MARK: - Default Implementations

public extension GnustoID {
    /// Convenience initializer for backward compatibility.
    /// - Parameter rawValue: The string value for the ID.
    init(_ rawValue: String) {
        assert(!rawValue.isEmpty, "\(Self.self) cannot be empty")
        self.init(rawValue: rawValue)
    }
    
    /// Initializes the ID using a string literal.
    /// - Parameter value: The string literal representing the ID.
    init(stringLiteral value: String) {
        assert(!value.isEmpty, "\(Self.self) cannot be empty")
        self.init(rawValue: value)
    }
    
    /// Creates a new ID from a decoder.
    /// Encodes as a plain string rather than an object with rawValue property.
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self.init(rawValue: rawValue)
    }
    
    /// Encodes this ID into the given encoder.
    /// Encodes as a plain string rather than an object with rawValue property.
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    /// Compares two IDs based on their raw values for ordering.
    /// - Parameters:
    ///   - lhs: An ID to compare.
    ///   - rhs: Another ID to compare.
    /// - Returns: `true` if the `rawValue` of `lhs` lexicographically precedes that of `rhs`.
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var description: String {
        ".\(rawValue)"
    }
}
