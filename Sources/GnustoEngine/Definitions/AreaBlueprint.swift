import Foundation

/// A protocol for types that define a collection of related game locations and items, forming
/// a logical region or area within the game world.
public protocol AreaBlueprint {
    /// Conforming types must provide an accessible default initializer.
    init()
}

extension AreaBlueprint {
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

    /// Discovers and returns all `ItemEventHandler` instances defined as properties within the
    /// conforming type.
    ///
    /// This method uses reflection to find `ItemEventHandler` properties whose names match the
    /// pattern `"{itemID}Handler"`, such as `cloakHandler` for the `.cloak` item.
    ///
    /// - Note: If a property is typed as `ItemEventHandler` but it does not conform to the
    ///         expected convention, an assertion failure occurs, and the handler is skipped.
    ///
    /// - Returns: A dictionary mapping each discovered `ItemID` to its corresponding
    ///            `ItemEventHandler`.
    public static var itemEventHandlers: [ItemID: ItemEventHandler] {
        let instance = Self()
        var handlers: [ItemID: ItemEventHandler] = [:]
        let mirror = Mirror(reflecting: instance)

        for child in mirror.children {
            guard
                let label = child.label,
                let handler = child.value as? ItemEventHandler
            else { continue }

            let handlerSuffix = "Handler"
            guard label.hasSuffix(handlerSuffix), label.count > handlerSuffix.count else {
                assertionFailure(
                    """
                    ItemEventHandler property '\(label)' in \(Self.self) does not follow the \ 
                    expected naming convention '{itemID}\(handlerSuffix)'. It will be skipped.
                    """
                )
                continue
            }
            let itemIDRawValue = String(label.dropLast(handlerSuffix.count))
            let itemID = ItemID(itemIDRawValue)
            handlers[itemID] = handler
        }

        return handlers
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

    /// Discovers and returns all `LocationEventHandler` instances defined as properties within the
    /// conforming type.
    ///
    /// This method uses reflection to find `LocationEventHandler` properties whose names match the
    /// pattern `"{itemID}Handler"`, such as `barHandler` for the `.bar` location.
    ///
    /// - Note: If a property is typed as `LocationEventHandler` but it does not conform to the
    ///         expected convention, an assertion failure occurs, and the handler is skipped.
    ///
    /// - Returns: A dictionary mapping each discovered `LocationID` to its corresponding
    ///            `LocationEventHandler`.
    public static var locationEventHandlers: [LocationID: LocationEventHandler] {
        let instance = Self()
        var handlers: [LocationID: LocationEventHandler] = [:]
        let mirror = Mirror(reflecting: instance)

        for child in mirror.children {
            guard
                let label = child.label,
                let handler = child.value as? LocationEventHandler
            else { continue }

            let handlerSuffix = "Handler"
            guard label.hasSuffix(handlerSuffix), label.count > handlerSuffix.count else {
                assertionFailure(
                    """
                    LocationEventHandler property '\(label)' in \(Self.self) does not follow the \ 
                    expected naming convention '{itemID}\(handlerSuffix)'. It will be skipped.
                    """
                )
                continue
            }
            let locationIDRawValue = String(label.dropLast(handlerSuffix.count))
            let locationID = LocationID(locationIDRawValue)
            handlers[locationID] = handler
        }

        return handlers
    }
}
