import Foundation // Needed for Codable conformance for classes

/// A closure that dynamically generates a description string for an Item based on its state and the overall GameState.
public typealias ItemDescriptionHandler = @MainActor @Sendable (Item, GameState) async -> String?

/// Represents an interactable object within the game world.
/// Note: Marked @unchecked Sendable due to the type-erased `dynamicProperties` dictionary.
/// Care must be taken if accessing/mutating this dictionary concurrently.
public struct Item: Codable, Identifiable, Sendable {
    // --- Stored Properties (Alphabetical) ---

    /// Adjectives associated with the item (e.g., ["brass", "small"]). Used for disambiguation.
    public var adjectives: Set<String>

    /// The maximum total size of items this item can contain. -1 signifies unlimited capacity (ZILF default).
    public var capacity: Int

    /// Storage for state values that might have associated dynamic behavior (computation/validation)
    /// defined externally in the `DynamicPropertyRegistry`.
    public var dynamicValues: [PropertyID: StateValue]

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
    /// Can be a static string or a dynamic handler closure.
    public var longDescription: ItemDescriptionHandler?

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
        longDescription: ItemDescriptionHandler? = nil,
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

        // Initialize dynamic values
        self.dynamicValues = [:] // Initialize as empty, game definition populates
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case adjectives
        case capacity
        case dynamicValues
        case shortDescription
        case firstDescription
        case heldText
        case id
        case name
        case parent
        case properties
        case size
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
        longDescription = nil // Set to nil on decode as it cannot be persisted
        synonyms = try container.decode(Set<String>.self, forKey: .synonyms)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        readableText = try container.decodeIfPresent(String.self, forKey: .readableText)
        lockKey = try container.decodeIfPresent(ItemID.self, forKey: .lockKey)

        // Decode dynamic values
        let stringKeyedValues: [String: StateValue] = try container.decodeIfPresent([String: StateValue].self, forKey: .dynamicValues) ?? [:]
        dynamicValues = Dictionary(uniqueKeysWithValues: stringKeyedValues.map { (key, value) in
            (PropertyID(key), value)
        })
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adjectives, forKey: .adjectives)
        try container.encode(capacity, forKey: .capacity)
        // Encode dynamic values - Encodes [String: StateValue]
        if !dynamicValues.isEmpty {
            // Convert PropertyID keys back to String keys for JSON representation
            let stringKeyedValues = Dictionary(uniqueKeysWithValues: dynamicValues.map { (key, value) in
                (key.rawValue, value)
            })
            try container.encode(stringKeyedValues, forKey: .dynamicValues)
        }
        try container.encodeIfPresent(shortDescription, forKey: .shortDescription)
        try container.encodeIfPresent(firstDescription, forKey: .firstDescription)
        try container.encodeIfPresent(heldText, forKey: .heldText)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(parent, forKey: .parent)
        try container.encode(properties, forKey: .properties)
        try container.encode(size, forKey: .size)
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

// MARK: - Equatable Conformance (Manual)

extension Item: Equatable {
    // Manually implement Equatable, ignoring the non-comparable closure property.
    public static func == (lhs: Item, rhs: Item) -> Bool {
        // Compare all properties *except* longDescription
        lhs.adjectives == rhs.adjectives &&
        lhs.capacity == rhs.capacity &&
        lhs.dynamicValues == rhs.dynamicValues &&
        lhs.shortDescription == rhs.shortDescription && // Assumes DescriptionHandler (String) is Equatable
        lhs.firstDescription == rhs.firstDescription && // Assumes DescriptionHandler (String) is Equatable
        lhs.heldText == rhs.heldText &&
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.parent == rhs.parent &&
        lhs.properties == rhs.properties &&
        lhs.size == rhs.size &&
        // lhs.longDescription == rhs.longDescription && // Omit closure comparison
        lhs.synonyms == rhs.synonyms &&
        lhs.text == rhs.text &&
        lhs.readableText == rhs.readableText &&
        lhs.lockKey == rhs.lockKey
        // Add any other properties if they exist
    }
}

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
