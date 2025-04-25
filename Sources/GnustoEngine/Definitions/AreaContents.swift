import Foundation

/// A protocol for types that define a collection of related game locations and items,
/// forming a logical region or area within the game world.
public protocol AreaContents {
    /// Conforming types must provide an accessible default initializer.
    init()
}

extension AreaContents {
    /// Returns all `Item` instances defined as properties within the conforming type.
    ///
    /// - Note: Uses reflection (`Mirror`) to find properties of type `Item`.
    /// - Throws: `fatalError` if duplicate `ItemID`s are found.
    /// - Returns: An array of all defined `Item` instances.
    public static var items: [Item] {
        let instance = Self()
        var seenIds = Set<ItemID>()
        let mirror = Mirror(reflecting: instance)

        return mirror.children.compactMap { child -> Item? in
            guard let item = child.value as? Item else { return nil }

            // Validate no duplicate IDs
            guard !seenIds.contains(item.id) else {
                fatalError("Duplicate ItemID '\(item.id)' found in \(Self.self).")
            }
            seenIds.insert(item.id)
            return item
        }
    }

    /// Returns all `Location` instances defined as properties within the conforming type.
    ///
    /// - Note: Uses reflection (`Mirror`) to find properties of type `Location`.
    /// - Throws: `fatalError` if duplicate `LocationID`s are found.
    /// - Returns: An array of all defined `Location` instances.
    public static var locations: [Location] {
        let instance = Self()
        var seenIds = Set<LocationID>()
        let mirror = Mirror(reflecting: instance)

        return mirror.children.compactMap { child -> Location? in
            guard let location = child.value as? Location else { return nil }

            // Validate no duplicate IDs
            guard !seenIds.contains(location.id) else {
                fatalError("Duplicate LocationID '\(location.id)' found in \(Self.self).")
            }
            seenIds.insert(location.id)
            return location
        }
    }
}
