import Foundation

/// Represents the runtime state of an active fuse, including both its turn countdown
/// and any custom state data that was provided when the fuse was started.
///
/// This structure allows fuses to maintain context-specific information across
/// game turns. For example, an enemy recovery fuse can store both the enemy ID and the
/// location ID where the enemy should return, preventing situations where the enemy spawns
/// in the player's current location instead of where they originally were.
public struct FuseState: Codable, Sendable, Equatable, Hashable {
    /// The number of game turns remaining until this fuse triggers.
    /// This value is decremented each turn by the game engine's timing system.
    public var turns: Int

    /// Custom state data associated with this fuse instance.
    /// This dictionary can store any context-specific information needed when the fuse triggers.
    /// Common use cases include entity IDs, location references, or fuse-specific parameters.
    public var dictionary: [String: StateValue]

    /// Initializes a new fuse state.
    ///
    /// - Parameters:
    ///   - turns: The number of turns until the fuse triggers (must be > 0).
    ///   - state: Optional custom state data for the fuse. Defaults to empty.
    public init(turns: Int, state: [String: StateValue] = [:]) {
        precondition(turns > 0, "Fuse state must have a positive turn count.")
        self.turns = turns
        self.dictionary = state
    }

    // MARK: - Convenience Access Methods

    /// Retrieves a string value from the fuse's state data.
    ///
    /// - Parameter key: The key to look up in the state dictionary.
    /// - Returns: The string value if found and convertible, otherwise `nil`.
    public func getString(_ key: String) -> String? {
        return dictionary[key]?.toString
    }

    /// Retrieves an integer value from the fuse's state data.
    ///
    /// - Parameter key: The key to look up in the state dictionary.
    /// - Returns: The integer value if found and convertible, otherwise `nil`.
    public func getInt(_ key: String) -> Int? {
        return dictionary[key]?.toInt
    }

    /// Retrieves a boolean value from the fuse's state data.
    ///
    /// - Parameter key: The key to look up in the state dictionary.
    /// - Returns: The boolean value if found and convertible, otherwise `nil`.
    public func getBool(_ key: String) -> Bool? {
        return dictionary[key]?.toBool
    }

    /// Retrieves an ItemID from the fuse's state data.
    ///
    /// - Parameter key: The key to look up in the state dictionary.
    /// - Returns: The ItemID if found and the value is a valid string, otherwise `nil`.
    public func getItemID(_ key: String) -> ItemID? {
        guard let stringValue = getString(key) else { return nil }
        return ItemID(rawValue: stringValue)
    }

    /// Retrieves a LocationID from the fuse's state data.
    ///
    /// - Parameter key: The key to look up in the state dictionary.
    /// - Returns: The LocationID if found and the value is a valid string, otherwise `nil`.
    public func getLocationID(_ key: String) -> LocationID? {
        guard let stringValue = getString(key) else { return nil }
        return LocationID(rawValue: stringValue)
    }
}
