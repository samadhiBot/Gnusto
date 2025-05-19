import Foundation

/// A protocol for types that group together the definitions for a specific area or region
/// of the game world, including its locations, items, and any associated event handlers.
///
/// Game developers conform to `AreaBlueprint` by creating a struct or class that holds
/// properties representing the static definitions for that area. For example:
///
/// ```swift
/// struct WestOfHouseArea: AreaBlueprint {
///     let livingRoom = Location(id: "livingRoom", ...)
///     let kitchen = Location(id: "kitchen", ...)
///     let brassLantern = Item(id: "brassLantern", ...)
///     let leaflet = Item(id: "leaflet", ...)
///
///     let livingRoomHandler = LocationEventHandler { engine, event in
///         // Custom logic for the living room
///         return nil
///     }
///
///     let leafletHandler = ItemEventHandler { engine, event in
///         // Custom logic for the leaflet
///         return nil
///     }
/// }
/// ```
///
/// The `AreaBlueprint` protocol extension then uses reflection to automatically discover
/// all `Location`, `Item`, `LocationEventHandler`, and `ItemEventHandler` instances
/// defined as properties within the conforming type. This allows for a declarative way
/// to define game content, which can then be aggregated by the `GameBlueprint`.
public protocol AreaBlueprint {
    /// Conforming types must provide an accessible default initializer (e.g., `init()`).
    /// This is necessary for the reflection-based discovery mechanism to instantiate
    /// the blueprint and access its properties.
    init()
}

extension AreaBlueprint {
    /// Discovers and returns all `Item` instances defined as properties within the conforming type.
    ///
    /// This method uses reflection (`Mirror`) to find all properties that are of type `Item`.
    /// It's crucial that each `Item` has a unique `ItemID` across the entire game to avoid conflicts.
    ///
    /// - Note: An assertion failure will occur during development if duplicate `ItemID`s are found
    ///         within this blueprint.
    /// - Returns: An array containing all `Item` instances defined as properties.
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
    /// conforming type, associating them with the corresponding `ItemID` based on a naming convention.
    ///
    /// The naming convention expected is `"<itemIDRawValue>Handler"`. For example, if an item has
    /// an `ItemID` of `"magicWand"`, its event handler property should be named `magicWandHandler`.
    ///
    /// ```swift
    /// let magicWand = Item(id: "magicWand", ...)
    /// let magicWandHandler = ItemEventHandler { ... }
    /// ```
    ///
    /// - Note: If a property is typed as `ItemEventHandler` but its name does not follow this
    ///         convention, an assertion failure will occur during development, and the handler
    ///         will be skipped.
    /// - Returns: A dictionary mapping each discovered `ItemID` to its `ItemEventHandler`.
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

    /// Discovers and returns all `Location` instances defined as properties within the conforming type.
    ///
    /// This method uses reflection (`Mirror`) to find all properties that are of type `Location`.
    /// Each `Location` must have a unique `LocationID` across the entire game.
    ///
    /// - Note: An assertion failure will occur during development if duplicate `LocationID`s are found
    ///         within this blueprint.
    /// - Returns: An array containing all `Location` instances defined as properties.
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
    /// conforming type, associating them by a naming convention.
    ///
    /// The naming convention expected is `"<locationIDRawValue>Handler"`. For example, if a location
    /// has a `LocationID` of `"grueLair"`, its event handler property should be named `grueLairHandler`.
    ///
    /// ```swift
    /// let grueLair = Location(id: "grueLair", ...)
    /// let grueLairHandler = LocationEventHandler { ... }
    /// ```
    ///
    /// - Note: If a property is typed as `LocationEventHandler` but its name does not follow this
    ///         convention, an assertion failure will occur during development, and the handler
    ///         will be skipped.
    /// - Returns: A dictionary mapping each discovered `LocationID` to its `LocationEventHandler`.
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
