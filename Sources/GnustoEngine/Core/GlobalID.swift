import Foundation

/// A type-safe key for accessing game-specific global variables or flags stored in
/// `GameState.globalState`.
///
/// `GlobalID`s provide a structured way to manage global state that isn't directly tied to
/// specific items or locations. This can include:
/// - Boolean flags indicating story progression (e.g., `GlobalID("metTheKing")`).
/// - Numeric counters for game-wide events (e.g., `GlobalID("dragonsSlain")`).
/// - Configuration settings or miscellaneous state values.
///
/// Using `GlobalID` instead of raw strings helps prevent typos and improves code clarity.
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for ease of use.
public struct GlobalID: GnustoID {
    public let rawValue: String

    /// Creates a new game state key with the specified string value.
    /// - Parameter rawValue: The string representation of the key.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Global ID cannot be empty")
        self.rawValue = rawValue
    }
}
