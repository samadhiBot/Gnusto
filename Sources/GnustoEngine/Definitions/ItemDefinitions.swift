import Foundation

public protocol ItemDefinitions {
    init()
}

extension ItemDefinitions {
    /// Returns all items defined in the Items struct, validating for duplicate IDs.
    /// - Returns: Array of all defined Items
    /// - Throws: Fatal error if duplicate item IDs are found
    public static func all() -> [Item] {
        let items = Self()
        var seenIds = Set<ItemID>()

        let mirror = Mirror(reflecting: items)
        return mirror.children.compactMap { child -> Item? in
            guard let item = child.value as? Item else { return nil }

            // Validate no duplicate IDs
            guard !seenIds.contains(item.id) else {
                fatalError("Duplicate item ID found: \(item.id)")
            }
            seenIds.insert(item.id)
            return item
        }
    }
}
