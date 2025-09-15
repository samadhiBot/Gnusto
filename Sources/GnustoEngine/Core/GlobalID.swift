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
        assert(rawValue.isNotEmpty, "Global ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - Standard Global IDs

extension GlobalID {
    /// Global state containing the combat state during active combat.
    public static let combatState = GlobalID("combatState")

    /// Flag indicating transcript recording is currently active.
    public static let isScripting = GlobalID("isScripting")

    /// Flag indicating verbose mode is enabled (show full location descriptions every time).
    public static let isVerboseMode = GlobalID("isVerboseMode")

    /// Flag used for no-operation state changes that have no effect on game state.
    public static let isNoOp = GlobalID("isNoOp")
}
