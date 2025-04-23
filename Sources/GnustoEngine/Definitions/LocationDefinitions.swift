import Foundation

public protocol LocationDefinitions {
    init()
}

extension LocationDefinitions {
    /// Returns all items defined in the Locations struct, validating for duplicate IDs.
    /// - Returns: Array of all defined Locations
    /// - Throws: Fatal error if duplicate item IDs are found
    public static func all() -> [Location] {
        let items = Self()
        var seenIds = Set<LocationID>()

        let mirror = Mirror(reflecting: items)
        return mirror.children.compactMap { child -> Location? in
            guard let item = child.value as? Location else { return nil }

            // Validate no duplicate IDs
            guard !seenIds.contains(item.id) else {
                fatalError("Duplicate item ID found: \(item.id)")
            }
            seenIds.insert(item.id)
            return item
        }
    }
}
