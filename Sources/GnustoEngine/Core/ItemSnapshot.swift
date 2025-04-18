import Foundation

/// A Sendable value type capturing the essential state of an Item at a particular moment.
/// Used for safely passing item information across actor boundaries.
public struct ItemSnapshot: Identifiable, Sendable {
    // --- Properties (Copies from Item) ---
    public let id: ItemID
    public let name: String
    public let adjectives: Set<String>
    public let synonyms: Set<String>
    public let description: String?
    public let firstDescription: String?
    public let subsequentDescription: String?
    public let text: String?
    public let heldText: String?
    public let properties: Set<ItemProperty>
    public let size: Int
    public let capacity: Int
    public let parent: ParentEntity
    public let readableText: String?

    // --- Initialization ---

    /// Creates a snapshot from an Item instance.
    init(item: Item) {
        self.id = item.id
        self.name = item.name
        self.adjectives = item.adjectives
        self.synonyms = item.synonyms
        self.description = item.description
        self.firstDescription = item.firstDescription
        self.subsequentDescription = item.subsequentDescription
        self.text = item.text
        self.heldText = item.heldText
        self.properties = item.properties // Set is a value type
        self.size = item.size
        self.capacity = item.capacity
        self.parent = item.parent // ParentEntity is a value type
        self.readableText = item.readableText // Copy readableText
    }

    // --- Convenience Accessors (Similar to Item) ---

    /// Checks if the snapshot indicates the item had a specific property.
    public func hasProperty(_ property: ItemProperty) -> Bool {
        properties.contains(property)
    }
}

extension ItemSnapshot: Comparable {
    public static func < (lhs: ItemSnapshot, rhs: ItemSnapshot) -> Bool {
        lhs.id < rhs.id
    }
}
