import Foundation

/// Represents a reference to a game entity, which can be an item, a location, or the player.
/// This provides a type-safe way to specify the target of a command.
public enum EntityReference: Hashable, Sendable, Codable {
    /// A reference to an item, identified by its `Item`.
    case item(Item)

    /// A reference to a location, identified by its `Location`.
    case location(Location)

    /// A reference to the player character.
    case player

    /// A reference to a universal object concept.
    case universal(UniversalObject)
}

extension EntityReference: CustomStringConvertible {
    public var description: String {
        switch self {
        case .item(let item): "\(item.id)"
        case .location(let location): "\(location.id)"
        case .player: "player"
        case .universal(let universal): "\(universal)"
        }
    }
}

extension EntityReference: Equatable {
    public static func == (lhs: EntityReference, rhs: EntityReference) -> Bool {
        switch (lhs, rhs) {
        case (.item(let lhsItem), .item(let rhsItem)):
            lhsItem.id == rhsItem.id
        case (.location(let lhsLocation), .location(let rhsLocation)):
            lhsLocation.id == rhsLocation.id
        case (.player, .player):
            true
        case (.universal(let lhsUniversal), .universal(let rhsUniversal)):
            lhsUniversal.id == rhsUniversal.id
        default:
            false
        }
    }
}
