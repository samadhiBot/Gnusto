import Foundation

/// Represents an interactive object in the game world.
public struct Item: Codable, Identifiable, Sendable {
    /// The item's unique identifier.
    public let id: ItemID

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public var name: String

    /// A dictionary that holds the item's current attributes.
    ///
    /// Some attributes are static under normal circumstances, but any can change when necessary.
    public var attributes: [AttributeID: StateValue]

    public init(
        id: ItemID,
        name: String,
        _ attributes: ItemAttribute...
    ) {
        self.id = id
        self.name = name
        self.attributes = Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.id, $0.rawValue) }
        )
    }

    @available(*, deprecated,
         renamed: "init(id:name:description:parent:_:)",
         message: "Please switch to the new syntax."
    )
    public init(
        id: ItemID,
        name: String,
        description: String? = nil,
        parent: ParentEntity? = nil,
        attributes: [AttributeID: StateValue] = [:]
    ) {
        self.id = id
        self.name = name
        self.attributes = attributes
        if let description {
            assert(attributes[.description] == nil, "Long description defined twice.")
            self.attributes[.description] = .string(description)
        }
        if let parent {
            self.attributes[.parentEntity] = .parentEntity(parent)
        }
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
