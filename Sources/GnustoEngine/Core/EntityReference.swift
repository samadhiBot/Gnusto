import Foundation

/// Represents a reference to a game entity, which can be an item, a location, or the player.
/// This provides a type-safe way to specify the target of a command.
public enum EntityReference: Hashable, Sendable, Codable {
    /// A reference to an item, identified by its `ItemID`.
    case item(ItemID)

    /// A reference to a location, identified by its `LocationID`.
    case location(LocationID)

    /// A reference to the player character.
    case player

    // Consider adding later if useful:
    // /// A reference to the current location where the command is being issued.
    // case here
    //
    // /// A reference to the entity that was the primary result/target of the previous action.
    // case previous
}

extension EntityReference: CustomStringConvertible {
    public var description: String {
        switch self {
        case .item(let itemID):
            itemID.rawValue
        case .location(let locationID):
            locationID.rawValue
        case .player:
            "yourself"
        }
    }
}
