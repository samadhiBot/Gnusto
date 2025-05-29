import Foundation

/// A protocol for types that group together the definitions for a specific area or region
/// of the game world, including its locations, items, and any associated event handlers.
///
/// ## Traditional Implementation
/// Game developers conform to `AreaBlueprint` by creating a struct that holds
/// properties representing the static definitions for that area:
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
/// ## Macro-Based Implementation (Recommended)
/// With the `@GameArea` macro, you can spread definitions across multiple files:
///
/// ```swift
/// @GameArea
/// struct Act1Area {
///     // Content discovered from extensions automatically
/// }
///
/// extension Act1Area {
///     @GameItem
///     static let basket = Item(.name("wicker basket"), .isTakable)
///
///     @GameLocation  
///     static let cottage = Location(.name("Your Cottage"))
///
///     @ItemEventHandler(.basket)
///     static let basketHandler = ItemEventHandler { ... }
/// }
/// ```
///
/// The `AreaBlueprint` protocol extension uses reflection (traditional) or macro generation
/// (modern) to automatically discover all content and create the appropriate collections.
public protocol AreaBlueprint {
    /// Conforming types must provide an accessible default initializer (e.g., `init()`).
    /// This is necessary for the reflection-based discovery mechanism to instantiate
    /// the blueprint and access its properties.
    init()
    
    /// All items defined in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameItem` marked properties across all extensions.
    static var items: [Item] { get }
    
    /// All locations defined in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameLocation` marked properties across all extensions.
    static var locations: [Location] { get }
    
    /// Event handlers for specific items in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@ItemEventHandler` marked properties across all extensions.
    static var itemEventHandlers: [ItemID: ItemEventHandler] { get }
    
    /// Event handlers for specific locations in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@LocationEventHandler` marked properties across all extensions.
    static var locationEventHandlers: [LocationID: LocationEventHandler] { get }
    
    /// Fuse definitions for this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameFuse` marked properties across all extensions.
    static var fuseDefinitions: [FuseID: FuseDefinition] { get }
    
    /// Daemon definitions for this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameDaemon` marked properties across all extensions.
    static var daemonDefinitions: [DaemonID: DaemonDefinition] { get }
    
    /// Dynamic attribute registry for this area.
    /// 
    /// With the `@GameArea` macro, this can be populated by discovering
    /// dynamic attribute handlers across all extensions.
    static var dynamicAttributeRegistry: DynamicAttributeRegistry { get }
}

// MARK: - Default Implementations

extension AreaBlueprint {
    /// Default implementation returns an empty fuse definitions dictionary.
    /// The `@GameArea` macro overrides this with discovered fuses.
    public static var fuseDefinitions: [FuseID: FuseDefinition] { [:] }
    
    /// Default implementation returns an empty daemon definitions dictionary.
    /// The `@GameArea` macro overrides this with discovered daemons.
    public static var daemonDefinitions: [DaemonID: DaemonDefinition] { [:] }
    
    /// Default implementation returns an empty dynamic attribute registry.
    /// The `@GameArea` macro overrides this with discovered dynamic attributes.
    public static var dynamicAttributeRegistry: DynamicAttributeRegistry { 
        DynamicAttributeRegistry() 
    }
}

// MARK: - Legacy Reflection-Based Discovery

extension AreaBlueprint {
    /// Discovers and returns all `Item` instances defined as properties within the conforming type.
    ///
    /// This method uses reflection (`Mirror`) to find all properties that are of type `Item`.
    /// It's crucial that each `Item` has a unique `ItemID` across the entire game to avoid conflicts.
    ///
    /// > Note: This is the legacy implementation. Use `@GameArea` macro for new areas.
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
    /// > Note: This is the legacy implementation. Use `@ItemEventHandler(.itemID)` macro for new handlers.
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
    /// > Note: This is the legacy implementation. Use `@GameArea` macro for new areas.
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
    /// > Note: This is the legacy implementation. Use `@LocationEventHandler(.locationID)` macro for new handlers.
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
