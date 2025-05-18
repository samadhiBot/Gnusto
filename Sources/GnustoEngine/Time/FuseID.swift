import Foundation

/// A type-safe, unique identifier for a `FuseDefinition` and its active instance
/// (timer) within the game state.
///
/// `FuseID`s are used to register fuse behaviors (timed events) in the `DefinitionRegistry`
/// and to track active fuses and their remaining turns in `GameState`.
public struct FuseID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Initializes an `FuseID` using a string literal.
    /// - Parameter value: The string literal representing the item ID.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// Initializes an `FuseID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: FuseID, rhs: FuseID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
