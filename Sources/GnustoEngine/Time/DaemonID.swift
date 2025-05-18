import Foundation

/// A type-safe, unique identifier for a `DaemonDefinition` and its active instance
/// within the game state.
///
/// `DaemonID`s are used to register daemon behaviors in the `DefinitionRegistry`
/// and to track active daemons in `GameState`.
public struct DaemonID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes an `DaemonID` using a string literal.
    /// - Parameter value: The string literal representing the item ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes an `DaemonID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: DaemonID, rhs: DaemonID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
