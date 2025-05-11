import Foundation

/// A protocol for types that define a collection of related game locations and items, forming
/// a logical region or area within the game world.
public protocol AreaContents {
    /// Conforming types must provide an accessible default initializer.
    init()
}

extension AreaContents {
    /// Returns all `Item` instances defined within array properties of the conforming type.
    ///
    /// - Note: Uses reflection (`Mirror`) to find properties of type `[Item]`.
    /// - Throws: `fatalError` if duplicate `ItemID`s are found across all arrays.
    /// - Returns: An array containing all defined `Item` instances from all `[Item]` properties.
    public static var items: [Item] {
        let instance = Self()
        var allItems: [Item] = []
        var seenIds = Set<ItemID>()
        let mirror = Mirror(reflecting: instance)

        for child in mirror.children {
            guard let item = child.value as? Item else { continue }
            assert(
                !seenIds.contains(item.id),
                "Duplicate item '\(item.id)' found in \(Self.self)."
            )
            seenIds.insert(item.id)
            allItems.append(item)
        }
        return allItems
    }

    /// Returns all `Location` instances defined within array properties of the conforming type.
    ///
    /// - Note: Uses reflection (`Mirror`) to find properties of type `[Location]`.
    /// - Throws: `fatalError` if duplicate `LocationID`s are found across all arrays.
    /// - Returns: An array containing all defined `Location` instances from all
    ///            `[Location]` properties.
    public static var locations: [Location] {
        let instance = Self()
        var allLocations: [Location] = []
        var seenIds = Set<LocationID>()
        let mirror = Mirror(reflecting: instance)

        for child in mirror.children {
            guard let location = child.value as? Location else { continue }
            assert(
                !seenIds.contains(location.id),
                "Duplicate location '\(location.id)' found in \(Self.self)."
            )
            seenIds.insert(location.id)
            allLocations.append(location)
        }
        return allLocations
    }
}
