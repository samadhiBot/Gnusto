import Foundation

/// A type-safe, unique identifier for an `Item` in the game world.
///
/// `ItemID` serves as the primary key for items, used to store and retrieve item data
/// in `GameState.items` and to refer to items in the `Vocabulary`, `SyntaxRule`s,
/// and game logic. Each item in a game must have a unique `ItemID`.
///
/// It is `Codable` for game state persistence and `ExpressibleByStringLiteral` for
/// convenient initialization (e.g., `let lanternID: ItemID = "brassLantern"`).
public struct ItemID: GnustoID {
    /// The underlying string value of the item identifier (e.g., "brassLantern").
    public let rawValue: String

    /// Initializes an `ItemID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Item ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - Standard Item IDs

public extension ItemID {
    /// Represents the player character as an item.
    static let player = ItemID("player")
}
