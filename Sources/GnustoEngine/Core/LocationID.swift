import CustomDump
import Foundation

/// A type-safe, unique identifier for a `Location` in the game world.
///
/// `LocationID` serves as the primary key for locations, used to store and retrieve
/// location data in `GameState.locations`, to define `Exit` destinations, and to refer
/// to locations in the `Vocabulary` and game logic. Each location in a game must have
/// a unique `LocationID`.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let clearingID: LocationID = "forestClearing"`).
public struct LocationID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    /// The underlying string value of the location identifier (e.g., "forestClearing").
    public let rawValue: String

    /// Initializes a `LocationID` using a string literal.
    /// - Parameter value: The string literal representing the location ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes a `LocationID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: LocationID, rhs: LocationID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomDumpStringConvertible conformance

extension LocationID: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        ".\(rawValue)"
    }
}
