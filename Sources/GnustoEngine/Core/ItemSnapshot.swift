import Foundation

/// A Sendable value type capturing the essential state of an Item at a particular moment.
/// Used for safely passing item information across actor boundaries.
public struct ItemSnapshot: Identifiable, Sendable {
    // --- Properties (Copies from Item) ---
    public let id: ItemID
    public let name: String
    public let adjectives: Set<String>
    public let synonyms: Set<String>
    public let shortDescription: DescriptionHandler?
    public let firstDescription: DescriptionHandler?
    public let longDescription: DescriptionHandler?
    public let text: String?
    public let heldText: String?
    public let properties: Set<ItemProperty>
    public let size: Int
    public let capacity: Int
    public let parent: ParentEntity
    public let readableText: String?
    public let lockKey: ItemID?

    // --- Initialization ---

    /// Creates a snapshot from an Item instance.
    init(item: Item) {
        self.id = item.id
        self.name = item.name
        self.adjectives = item.adjectives
        self.synonyms = item.synonyms
        self.shortDescription = item.shortDescription
        self.firstDescription = item.firstDescription
        self.longDescription = item.longDescription
        self.text = item.text
        self.heldText = item.heldText
        self.properties = item.properties // Set is a value type
        self.size = item.size
        self.capacity = item.capacity
        self.parent = item.parent // ParentEntity is a value type
        self.readableText = item.readableText // Copy readableText
        self.lockKey = item.lockKey // Copy lockKey
    }

    // --- Convenience Accessors (Similar to Item) ---

    /// Checks if the snapshot indicates the item had a specific property.
    public func hasProperty(_ property: ItemProperty) -> Bool {
        properties.contains(property)
    }

    // --- Matching Logic ---

    /// Checks if the provided noun matches the item's name or synonyms.
    /// Case-insensitive comparison.
    func matches(noun: String) -> Bool {
        let lowerNoun = noun.lowercased()
        if self.name.lowercased() == lowerNoun {
            return true
        }
        return self.synonyms.contains { $0.lowercased() == lowerNoun }
    }

    /// Checks if the provided set of adjectives is a subset of the item's adjectives.
    /// Case-insensitive comparison.
    func matches(adjectives: Set<String>) -> Bool {
        guard !adjectives.isEmpty else {
            // If no adjectives are provided, it's considered a match
            // (we are only checking the noun in this case).
            return true
        }
        let lowerAdjectives = Set(self.adjectives.map { $0.lowercased() })
        let lowerInputAdjectives = Set(adjectives.map { $0.lowercased() })
        return lowerInputAdjectives.isSubset(of: lowerAdjectives)
    }
}

extension ItemSnapshot: Comparable {
    public static func < (lhs: ItemSnapshot, rhs: ItemSnapshot) -> Bool {
        lhs.id < rhs.id
    }
}
