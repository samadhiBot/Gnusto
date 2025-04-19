import Foundation // Needed for Codable conformance for classes

/// Represents an interactable object within the game world. Modeled as a class for reference semantics.
public final class Item: Codable, Identifiable {

    // --- Stored Properties (Alphabetical) ---

    /// Adjectives associated with the item (e.g., ["brass", "small"]). Used for disambiguation.
    public var adjectives: Set<String>

    /// The maximum total size of items this item can contain. -1 signifies unlimited capacity (ZILF default).
    public var capacity: Int

    // Action handler - Placeholder.
    // var actionHandlerID: String?

    /// The description shown when the item is examined (`EXAMINE`).
    public var description: String?

    /// The description shown when the item is first seen in a room (`FDESC`).
    public var firstDescription: String?

    /// Text displayed only when the item is held and read (`READ`, requires `ItemProperty.read`).
    public var heldText: String?

    /// The unique identifier for this item. `let` because identity doesn't change.
    public let id: ItemID

    /// The primary noun used to refer to the item (e.g., "lantern").
    public var name: String

    /// The entity that currently contains or supports this item.
    public var parent: ParentEntity

    /// The set of properties defining the item's characteristics and capabilities.
    public var properties: Set<ItemProperty>

    /// The item's size, influencing carrying capacity and container limits. Defaults to 5 per ZILF docs.
    public var size: Int

    /// The description shown when the item is present in a room after the first time (`LDESC`).
    public var subsequentDescription: String?

    /// Synonyms for the item's name (e.g., ["lamp", "light"]).
    public var synonyms: Set<String>

    /// Text displayed when the item is read (`READ`, requires `ItemProperty.read`).
    public var text: String?

    /// The text content if the item is `.readable`.
    public var readableText: String? = nil

    /// The key needed to lock/unlock this item (if `.lockable`).
    public var lockKey: ItemID? = nil

    // --- Initialization ---

    public init(
        id: ItemID,
        name: String,
        adjectives: String...,
        synonyms: String...,
        description: String? = nil,
        firstDescription: String? = nil,
        subsequentDescription: String? = nil,
        text: String? = nil,
        heldText: String? = nil,
        properties: ItemProperty...,
        size: Int = 5,
        capacity: Int = -1,
        parent: ParentEntity = .nowhere, // Default parent to .nowhere
        readableText: String? = nil,
        lockKey: ItemID? = nil
        // actionHandlerID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.adjectives = Set(adjectives)
        self.synonyms = Set(synonyms)
        self.description = description
        self.firstDescription = firstDescription
        self.subsequentDescription = subsequentDescription
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

    init(
        id: ItemID,
        name: String,
        adjectives: Set<String> = [],
        synonyms: Set<String> = [],
        description: String? = nil,
        firstDescription: String? = nil,
        subsequentDescription: String? = nil,
        text: String? = nil,
        heldText: String? = nil,
        properties: Set<ItemProperty> = [],
        size: Int = 5,
        capacity: Int = -1,
        parent: ParentEntity = .nowhere, // Default parent to .nowhere
        readableText: String? = nil,
        lockKey: ItemID? = nil
        // actionHandlerID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.adjectives = adjectives
        self.synonyms = synonyms
        self.description = description
        self.firstDescription = firstDescription
        self.subsequentDescription = subsequentDescription
        self.text = text
        self.heldText = heldText
        self.properties = properties
        self.size = size
        self.capacity = capacity
        self.parent = parent
        self.readableText = readableText
        self.lockKey = lockKey
        // self.actionHandlerID = actionHandlerID
    }

    // --- Codable Conformance ---
    // Classes require explicit implementation for Codable

    enum CodingKeys: String, CodingKey {
        case adjectives
        case capacity
        case description
        case firstDescription
        case heldText
        case id
        case name
        case parent
        case properties
        case size
        case subsequentDescription
        case synonyms
        case text
        case readableText
        case lockKey
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adjectives = try container.decode(Set<String>.self, forKey: .adjectives)
        capacity = try container.decode(Int.self, forKey: .capacity)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        firstDescription = try container.decodeIfPresent(String.self, forKey: .firstDescription)
        heldText = try container.decodeIfPresent(String.self, forKey: .heldText)
        id = try container.decode(ItemID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        parent = try container.decode(ParentEntity.self, forKey: .parent)
        properties = try container.decode(Set<ItemProperty>.self, forKey: .properties)
        size = try container.decode(Int.self, forKey: .size)
        subsequentDescription = try container.decodeIfPresent(String.self, forKey: .subsequentDescription)
        synonyms = try container.decode(Set<String>.self, forKey: .synonyms)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        readableText = try container.decodeIfPresent(String.self, forKey: .readableText)
        lockKey = try container.decodeIfPresent(ItemID.self, forKey: .lockKey)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adjectives, forKey: .adjectives)
        try container.encode(capacity, forKey: .capacity)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(firstDescription, forKey: .firstDescription)
        try container.encodeIfPresent(heldText, forKey: .heldText)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(parent, forKey: .parent)
        try container.encode(properties, forKey: .properties)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(subsequentDescription, forKey: .subsequentDescription)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(readableText, forKey: .readableText)
        try container.encodeIfPresent(lockKey, forKey: .lockKey)
    }

    // --- Convenience Accessors ---

    /// Checks if the item has a specific property.
    /// - Parameter property: The `ItemProperty` to check for.
    /// - Returns: `true` if the item has the property, `false` otherwise.
    public func hasProperty(_ property: ItemProperty) -> Bool {
        properties.contains(property)
    }

    /// Adds a property to the item.
    /// - Parameter property: The `ItemProperty` to add.
    public func addProperty(_ property: ItemProperty) {
        properties.insert(property)
    }

    /// Removes a property from the item.
    /// - Parameter property: The `ItemProperty` to remove.
    public func removeProperty(_ property: ItemProperty) {
        properties.remove(property)
    }
}
