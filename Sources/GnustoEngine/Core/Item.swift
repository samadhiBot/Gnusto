import Foundation

/// Represents an interactive object in the game world.
public struct Item: Codable, Identifiable, Sendable {
    /// The item's unique identifier.
    public let id: ItemID

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public var name: String

    /// The entity that currently contains or supports this item (ZIL: `IN`)
    public var parent: ParentEntity

    /// A dictionary that holds the item's current attributes.
    ///
    /// Some attributes are static under normal circumstances, but any can change when necessary.
    public var attributes: [AttributeID: StateValue]

    public init(
        id: ItemID,
        name: String,
        description: String? = nil,
        parent: ParentEntity = .nowhere,
        attributes: [AttributeID: StateValue] = [:]
    ) {
        self.id = id
        self.name = name
        self.parent = parent
        var initial = attributes
        if let description {
            initial[.longDescription] = .string(description)
        }
        self.attributes = initial
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
    /// - Parameter id: The `AttributeID` of the flag to check.
    /// - Returns: `true` if the flag exists and is set to `true`, `false` otherwise.
    public func hasFlag(_ id: AttributeID) -> Bool {
        attributes[id] == true
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

// MARK: - Equatable Conformance

// Equatable conformance will be synthesized

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
