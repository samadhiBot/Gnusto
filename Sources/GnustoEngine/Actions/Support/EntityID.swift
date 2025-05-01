/// Identifies the specific entity whose state is being changed.
public enum EntityID: Codable, Sendable, Hashable {
    /// Refers to an item via its unique ID.
    case item(ItemID)

    /// Refers to a location via its unique ID.
    case location(LocationID)

    /// Refers to the player entity.
    case player

    /// Refers to global state not tied to a specific item or location (e.g., flags, pronouns).
    case global
}
