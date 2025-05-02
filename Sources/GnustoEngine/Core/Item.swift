import Foundation // Needed for Codable conformance for classes

/// Represents an interactable object within the game world.
public struct Item: Codable, Identifiable, Sendable {

    // --- Stored Properties (Alphabetical) ---

    /// Adjectives associated with the item (e.g., ["brass", "small"]). Used for disambiguation.
    public var adjectives: Set<String>

    /// The maximum total size of items this item can contain. -1 signifies unlimited capacity (ZILF default).
    public var capacity: Int

    // Action handler - Placeholder.
    // var actionHandlerID: String?

    /// The short description shown in room listings and when the item is mentioned (ZIL DESC).
    public var shortDescription: DescriptionHandler?

    /// The description shown when the item is first seen in a room (ZIL FDESC).
    public var firstDescription: DescriptionHandler?

    /// Text displayed only when the item is held and read (`READ`, requires `ItemProperty.read`).
    public var heldText: String?

    /// The unique identifier for this item (ZIL NAME). `let` because identity doesn't change.
    public let id: ItemID

    /// The primary noun used to refer to the item (e.g., "lantern").
    public var name: String

    /// The entity that currently contains or supports this item.
    public var parent: ParentEntity

    /// The set of properties defining the item's characteristics and capabilities.
    public var properties: Set<ItemProperty>

    /// The item's size, influencing carrying capacity and container limits. Defaults to 5 per ZILF docs.
    public var size: Int

    /// The detailed description shown when examining the item (ZIL LDESC).
    public var longDescription: DescriptionHandler?

    /// Synonyms for the item's name (e.g., ["lamp", "light"]).
    public var synonyms: Set<String>

    /// Text displayed when the item is read (`READ`, requires `ItemProperty.read`).
    public var text: String?

    /// The text content if the item is `.readable`.
    public var readableText: String? = nil

    /// The key needed to lock/unlock this item (if `.lockable`).
    public var lockKey: ItemID? = nil

    public init(
        id: ItemID,
        name: String,
        adjectives: String...,
        synonyms: String...,
        shortDescription: DescriptionHandler? = nil,
        firstDescription: DescriptionHandler? = nil,
        longDescription: DescriptionHandler? = nil,
        text: String? = nil,
        heldText: String? = nil,
        properties: ItemProperty...,
        size: Int = 5,
        capacity: Int = -1,
        parent: ParentEntity = .nowhere,
        readableText: String? = nil,
        lockKey: ItemID? = nil
        // actionHandlerID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.adjectives = Set(adjectives)
        self.synonyms = Set(synonyms)
        self.shortDescription = shortDescription
        self.firstDescription = firstDescription
        self.longDescription = longDescription
        self.text = text
        self.heldText = heldText
        self.properties = Set(properties)
        self.size = size
        self.capacity = capacity
        self.parent = parent
        self.readableText = readableText
        self.lockKey = lockKey
        // self.actionHandlerID = actionHandlerID
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case adjectives
        case capacity
        case shortDescription
        case firstDescription
        case heldText
        case id
        case name
        case parent
        case properties
        case size
        case longDescription
        case synonyms
        case text
        case readableText
        case lockKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adjectives = try container.decode(Set<String>.self, forKey: .adjectives)
        capacity = try container.decode(Int.self, forKey: .capacity)
        shortDescription = try container.decodeIfPresent(DescriptionHandler.self, forKey: .shortDescription)
        firstDescription = try container.decodeIfPresent(DescriptionHandler.self, forKey: .firstDescription)
        heldText = try container.decodeIfPresent(String.self, forKey: .heldText)
        id = try container.decode(ItemID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        parent = try container.decode(ParentEntity.self, forKey: .parent)
        properties = try container.decode(Set<ItemProperty>.self, forKey: .properties)
        size = try container.decode(Int.self, forKey: .size)
        longDescription = try container.decodeIfPresent(DescriptionHandler.self, forKey: .longDescription)
        synonyms = try container.decode(Set<String>.self, forKey: .synonyms)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        readableText = try container.decodeIfPresent(String.self, forKey: .readableText)
        lockKey = try container.decodeIfPresent(ItemID.self, forKey: .lockKey)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adjectives, forKey: .adjectives)
        try container.encode(capacity, forKey: .capacity)
        try container.encodeIfPresent(shortDescription, forKey: .shortDescription)
        try container.encodeIfPresent(firstDescription, forKey: .firstDescription)
        try container.encodeIfPresent(heldText, forKey: .heldText)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(parent, forKey: .parent)
        try container.encode(properties, forKey: .properties)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(longDescription, forKey: .longDescription)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(readableText, forKey: .readableText)
        try container.encodeIfPresent(lockKey, forKey: .lockKey)
    }

    /// Adds a property to the item.
    /// - Parameter property: The `ItemProperty` to add.
    public mutating func addProperty(_ property: ItemProperty) {
        properties.insert(property)
    }

    /// Removes a property from the item.
    /// - Parameter property: The `ItemProperty` to remove.
    public mutating func removeProperty(_ property: ItemProperty) {
        properties.remove(property)
    }
}

// MARK: - Convenience Accessors

extension Item {

    /// Checks if the item has a specific property.
    /// - Parameter property: The `ItemProperty` to check for.
    /// - Returns: `true` if the item has the property, `false` otherwise.
    public func hasProperty(_ property: ItemProperty) -> Bool {
        properties.contains(property)
    }
}

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
