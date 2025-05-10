import Foundation

/// Represents an interactive object in the game world.
public struct Item: Codable, Identifiable, Sendable {
    /// The item's unique identifier.
    public let id: ItemID

    /// A dictionary that holds all of the item's mutable attributes.
    public var attributes: [AttributeID: StateValue]
    
    /// Creates a new `Item` instance.
    ///
    /// - Parameters:
    ///   - id: The item's unique identifier.
    ///   - attributes: All of the item's attributes.
    public init(
        id: ItemID,
        _ attributes: ItemAttribute...
    ) {
        self.id = id
        self.attributes = Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.id, $0.rawValue) }
        )
    }

    // MARK: - Convenience Accessors

    /// Adjectives associated with the item (e.g., "brass", "small" for lantern).
    public var adjectives: Set<String> {
        attributes[.adjectives]?.toStrings ?? []
    }

    /// The item's capacity to store other objects.
    public var capacity: Int {
        attributes[.capacity]?.toInt ?? 1000
    }

    /// Checks if a boolean flag is set in the item's `attributes`.
    ///
    /// - Parameter id: The `AttributeID` of the flag to check.
    /// - Returns: `true` if the flag exists and is set to `true`, `false` otherwise.
    public func hasFlag(_ id: AttributeID) -> Bool {
        attributes[id] == true
    }

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public var name: String {
        attributes[.name]?.toString ?? id.rawValue
    }

    /// The entity that currently contains or supports this item (ZIL: `IN`)
    public var parent: ParentEntity {
        attributes[.parentEntity]?.toParentEntity ?? .nowhere
    }

    /// The item's size.
    public var size: Int {
        attributes[.size]?.toInt ?? 1
    }

    /// Synonyms for the item (e.g., "lamp", "light" for lantern).
    public var synonyms: Set<String> {
        attributes[.synonyms]?.toStrings ?? []
    }
}

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
