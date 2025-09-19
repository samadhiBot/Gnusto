import Foundation

/// A proxy type that represents the parent container of a game entity.
///
/// `ParentProxy` encapsulates the different types of containers that can hold game entities,
/// providing a type-safe way to represent parent-child relationships in the game world.
public enum ParentProxy: Hashable, Sendable {
    /// The parent is an item, containing the associated item proxy.
    case item(ItemProxy)

    /// The parent is a location, containing the associated location proxy.
    case location(LocationProxy)

    /// The entity has no parent (exists nowhere in the game world).
    case nowhere

    /// The parent is the player character.
    case player
}

extension ParentProxy {
    /// Converts the proxy back to its corresponding `ParentEntity` representation.
    ///
    /// This computed property extracts the entity identifiers from the proxy objects
    /// and returns a `ParentEntity` enum value that can be stored or transmitted.
    ///
    /// - Returns: A `ParentEntity` that represents the same parent relationship
    ///   but contains only the entity identifiers rather than full proxy objects.
    public var entity: ParentEntity {
        switch self {
        case .item(let itemProxy):
            .item(itemProxy.id)
        case .location(let locationProxy):
            .location(locationProxy.id)
        case .nowhere:
            .nowhere
        case .player:
            .player
        }
    }
}

// MARK: - Convenience Extensions

extension GameEngine {
    /// Creates a `ParentProxy` from the specified parent entity.
    ///
    /// This method converts a `ParentEntity` enum value into a corresponding `ParentProxy`
    /// that provides access to the actual proxy objects for items and locations.
    ///
    /// - Parameter parentEntity: The parent entity to convert into a proxy.
    /// - Returns: A `ParentProxy` instance that wraps the appropriate proxy type.
    public func parent(from parentEntity: ParentEntity) -> ParentProxy {
        switch parentEntity {
        case .item(let itemID):
            .item(self.item(itemID))
        case .location(let locationID):
            .location(self.location(locationID))
        case .nowhere:
            .nowhere
        case .player:
            .player
        }
    }
}
