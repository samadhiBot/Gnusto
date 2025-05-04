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
    ///
    /// Use this for mutable state that changes during gameplay (e.g., open/closed status, charge level,
    /// description text that depends on game state). Values are keyed by `PropertyID` constants
    /// (e.g., `.longDescription`, `.itemReadText`, `.isOpen`).
    ///
    /// This dictionary represents the *current state* of the item's dynamic aspects.
    /// Access and modification should typically go through `GameEngine` helper methods
    /// (like `getDynamicItemValue`, `setDynamicItemValue`) to ensure any associated
    /// computation or validation logic is correctly applied.
    ///
    /// Values are typically represented using the `StateValue` enum (e.g., `.string`, `.bool`, `.int`).
    public var dynamicValues: [PropertyID: StateValue]

    // Action handler - Placeholder.
    // var actionHandlerID: String?

    /// Represents the unique identifier for this item.
    public let id: ItemID

    /// The primary noun used to refer to the item (e.g., "lantern").
    public var name: String

    /// The entity that currently contains or supports this item.
    public var parent: ParentEntity

    /// The set of inherent, relatively static properties defining the item's fundamental
    /// characteristics and capabilities (e.g., is it a container, a light source, wearable?).
    ///
    /// These properties define *what* the item *is* or *can do* fundamentally, and are less
    /// likely to change frequently during gameplay compared to `dynamicValues`. They are
    /// represented by the `ItemProperty` enum.
    public var properties: Set<ItemProperty>

    /// The item's size, influencing carrying capacity and container limits. Defaults to 5 per ZILF docs.
    public var size: Int

    /// Synonyms for the item's name (e.g., ["lamp", "light"]).
    public var synonyms: Set<String>

    /// The key needed to lock/unlock this item (if `.lockable`).
    public var lockKey: ItemID? = nil

    public init(
        id: ItemID,
        name: String,
        adjectives: String...,
        synonyms: String...,
        shortDescription: String? = nil,
        firstDescription: String? = nil,
        longDescription: String? = nil,
        readText: String? = nil,      // Renamed from 'text'/'readableText'
        heldText: String? = nil,
        properties: ItemProperty...,
        dynamicValues: [PropertyID: StateValue] = [:],
        size: Int = 5,
        capacity: Int = -1,
        parent: ParentEntity = .nowhere,
        lockKey: ItemID? = nil
        // actionHandlerID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.adjectives = Set(adjectives)
        self.synonyms = Set(synonyms)
        self.properties = Set(properties)
        self.size = size
        self.capacity = capacity
        self.parent = parent
        self.lockKey = lockKey
        // self.actionHandlerID = actionHandlerID

        // Initialize dynamic values
        var initialValues = [PropertyID: StateValue]()
        if let shortDescription {
            initialValues[.shortDescription] = .string(shortDescription)
        }
        if let firstDescription {
            initialValues[.itemFirstDescription] = .string(firstDescription)
        }
        if let longDescription {
            initialValues[.longDescription] = .string(longDescription)
        }
        if let readText {
            initialValues[.itemReadText] = .string(readText)
        }
        if let heldText {
            initialValues[.itemHeldText] = .string(heldText)
        }
        self.dynamicValues = initialValues
    }

    // MARK: - Codable Conformance

    private enum CodingKeys: String, CodingKey {
        case id, name, adjectives, synonyms, properties, size, capacity, parent, lockKey, dynamicValues
        // Note: Removed keys for old description properties
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ItemID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        adjectives = try container.decode(Set<String>.self, forKey: .adjectives)
        synonyms = try container.decode(Set<String>.self, forKey: .synonyms)
        properties = try container.decode(Set<ItemProperty>.self, forKey: .properties)
        size = try container.decode(Int.self, forKey: .size)
        capacity = try container.decode(Int.self, forKey: .capacity)
        parent = try container.decode(ParentEntity.self, forKey: .parent)
        lockKey = try container.decodeIfPresent(ItemID.self, forKey: .lockKey)
        dynamicValues = try container.decode([PropertyID: StateValue].self, forKey: .dynamicValues)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(adjectives, forKey: .adjectives)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encode(properties, forKey: .properties)
        try container.encode(size, forKey: .size)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(parent, forKey: .parent)
        try container.encodeIfPresent(lockKey, forKey: .lockKey)
        try container.encode(dynamicValues, forKey: .dynamicValues)
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

// MARK: - Equatable Conformance

// Equatable conformance will be synthesized

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
