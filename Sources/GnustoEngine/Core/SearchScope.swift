/// Defines the scope for searching for items.
public enum SearchScope: Sendable {
    /// Search only the player's inventory.
    case inventory

    /// Search only the items accessible in the player's current location.
    case location

    /// Search both the player's inventory and the current location.
    case both
}
