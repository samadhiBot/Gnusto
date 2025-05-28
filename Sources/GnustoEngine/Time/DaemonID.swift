import Foundation

/// A type-safe identifier for a daemon (background process) in the game's time system.
///
/// A daemon is a piece of game logic that runs automatically each turn, typically used
/// for ongoing background processes like NPC behavior, environmental changes, or
/// recurring events.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let thiefDaemonID: DaemonID = "thief"`).
public struct DaemonID: RawRepresentable, Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    /// The underlying string value of the daemon identifier.
    public let rawValue: String

    /// Initializes a `DaemonID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Convenience initializer for backward compatibility.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Initializes a `DaemonID` using a string literal.
    /// - Parameter value: The string literal representing the daemon ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Creates a new DaemonID from a decoder.
    /// Required for `Codable` conformance.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// Encodes this DaemonID into the given encoder.
    /// Required for `Codable` conformance.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public static func < (lhs: DaemonID, rhs: DaemonID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
