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

        // Initialize dynamic values
        self.dynamicValues = [:] // Initialize as empty, game definition populates
    }

    // MARK: - Codable Conformance

    // Codable conformance will be synthesized (DescriptionHandler is Codable)

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

// Equatable conformance will be synthesized (DescriptionHandler is Equatable)

// MARK: - Comparable conformance

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.id < rhs.id
    }
}
