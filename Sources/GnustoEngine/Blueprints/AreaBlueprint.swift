import Foundation

/// A protocol for types that group together the definitions for a specific area or region
/// of the game world, including its locations, items, and any associated event handlers.
///
/// ## Macro-Based Implementation (Recommended)
/// With the `@GameArea` macro, you can define areas using enums for clean namespacing:
///
/// ```swift
/// @GameArea
/// enum Act1Area {
///     @GameItem
///     static let basket = Item(id: "basket", .name("wicker basket"), .isTakable)
///
///     @GameLocation  
///     static let cottage = Location(id: "cottage", .name("Your Cottage"))
/// }
/// // Generates:
/// // extension ItemID { static let basket = ItemID("basket") }
/// // extension LocationID { static let cottage = LocationID("cottage") }
/// ```
///
/// The `@GameArea` macro automatically discovers all content and creates the appropriate collections.
public protocol AreaBlueprint {
    /// All items defined in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameItem` marked properties.
    static var items: [Item] { get }
    
    /// All locations defined in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameLocation` marked properties.
    static var locations: [Location] { get }
    
    /// Event handlers for specific items in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@ItemEventHandler` marked properties.
    static var itemEventHandlers: [ItemID: ItemEventHandler] { get }
    
    /// Event handlers for specific locations in this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@LocationEventHandler` marked properties.
    static var locationEventHandlers: [LocationID: LocationEventHandler] { get }
    
    /// Fuse definitions for this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameFuse` marked properties.
    static var fuseDefinitions: [FuseID: FuseDefinition] { get }
    
    /// Daemon definitions for this area.
    /// 
    /// With the `@GameArea` macro, this is automatically populated by discovering
    /// all `@GameDaemon` marked properties.
    static var daemonDefinitions: [DaemonID: DaemonDefinition] { get }
    
    /// Dynamic attribute registry for this area.
    /// 
    /// With the `@GameArea` macro, this can be populated by discovering
    /// dynamic attribute handlers.
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