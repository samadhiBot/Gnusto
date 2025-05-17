import CustomDump

/// Represents the possible parents of an Item in the game hierarchy, determining its location
/// or containment state.
public enum ParentEntity: Hashable, Codable, Equatable, Sendable {
    /// The item is contained within or supported by another item.
    case item(ItemID)
    
    /// The item is directly within a location.
    case location(LocationID)

    /// Represents an item not currently in the active game world (e.g., uninitialized, destroyed,
    /// or in a theoretical 'limbo'). This helps distinguish items that *exist* in the master item
    /// list but aren't 'anywhere' yet.
    case nowhere

    /// The item is held directly by the player.
    case player
}

// MARK: - CustomDumpStringConvertible conformance

extension ParentEntity: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        switch self {
        case .item(let id): ".item(\(id.customDumpDescription))"
        case .location(let id): ".location(\(id.customDumpDescription))"
        case .nowhere: ".nowhere"
        case .player: ".player"
        }
    }
}
