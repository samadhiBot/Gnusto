import Foundation

/// A type-safe identifier for a fuse (timed event) in the game's time system.
///
/// A fuse is a one-time event that triggers after a specific number of turns,
/// typically used for time-limited situations like bombs, timers, or delayed reactions.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let bombFuseID: FuseID = "bombFuse"`).
public struct FuseID: RawRepresentable, Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    /// The underlying string value of the fuse identifier.
    public let rawValue: String

    /// Initializes a `FuseID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Convenience initializer for backward compatibility.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Initializes a `FuseID` using a string literal.
    /// - Parameter value: The string literal representing the fuse ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Creates a new FuseID from a decoder.
    /// Required for `Codable` conformance.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes this FuseID into the given encoder.
    /// Required for `Codable` conformance.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public static func < (lhs: FuseID, rhs: FuseID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
