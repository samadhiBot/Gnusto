/// Represents the possible parents of an Item in the game hierarchy,
/// determining its location or containment state.
public enum ParentEntity: Hashable, Codable, Equatable, Sendable {
    /// The item is directly within a location.
    case location(LocationID)

    /// The item is contained within or supported by another item.
    case item(ItemID)

    /// The item is held directly by the player.
    case player

    /// Represents an item not currently in the active game world (e.g., uninitialized, destroyed, or in a theoretical 'limbo').
    /// This helps distinguish items that *exist* in the master item list but aren't 'anywhere' yet.
    case nowhere
}
