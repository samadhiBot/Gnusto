import SwiftSyntax
import SwiftSyntaxMacros
import SwiftCompilerPlugin

/// The main macro for defining a complete game with convention-based discovery.
///
/// This macro:
/// 1. Discovers all `*Area` types in the module that conform to `AreaBlueprint`
/// 2. Generates the complete `GameBlueprint` conformance
/// 3. Auto-generates all ID constants
/// 4. Validates cross-references between areas
///
/// Usage:
/// ```swift
/// @GameBlueprint(
///     title: "My Game",
///     introduction: "Welcome to my game...",
///     maxScore: 100,
///     startingLocation: .startRoom
/// )
/// struct MyGame {
///     // Everything else is automatic!
/// }
/// ```
@attached(member, names: arbitrary)
@attached(conformance, names: named(GameBlueprint))
public macro GameBlueprint(
    title: String,
    introduction: String,
    maxScore: Int,
    startingLocation: ItemID? = nil
) = #externalMacro(module: "GnustoMacros", type: "GameBlueprintMacro")

/// Marks a struct as a game area with automatic discovery of items, locations, and handlers.
///
/// This macro:
/// 1. Scans all extensions of the marked type across all files in the module
/// 2. Discovers `@GameItem`, `@GameLocation`, `@ItemEventHandler`, etc. declarations
/// 3. Generates the complete `AreaBlueprint` conformance
/// 4. Auto-generates ID constants for all discovered items/locations
/// 5. Validates all cross-references within the area
///
/// Usage:
/// ```swift
/// @GameArea
/// struct Act1Area {
///     // Items, locations, handlers discovered from extensions
/// }
/// ```
@attached(member, names: arbitrary)
@attached(conformance, names: named(AreaBlueprint))
public macro GameArea() = #externalMacro(module: "GnustoMacros", type: "GameAreaMacro")

/// Marks a static property as a game item with automatic ID generation.
///
/// The item ID is auto-generated from the property name using camelCase conversion.
/// For example, `sourdoughBoule` becomes `ItemID("sourdoughBoule")`.
///
/// Usage:
/// ```swift
/// extension MyArea {
///     @GameItem
///     static let magicSword = Item(
///         .name("magic sword"),
///         .in(.location(.armory))
///     )
/// }
/// ```
@attached(peer)
public macro GameItem() = #externalMacro(module: "GnustoMacros", type: "GameItemMacro")

/// Marks a static property as a game location with automatic ID generation.
///
/// Usage:
/// ```swift
/// extension MyArea {
///     @GameLocation
///     static let throneRoom = Location(
///         .name("Throne Room"),
///         .exits([.north: .to(.greatHall)])
///     )
/// }
/// ```
@attached(peer)
public macro GameLocation() = #externalMacro(module: "GnustoMacros", type: "GameLocationMacro")

/// Marks an item event handler with automatic association to the specified item.
///
/// Usage:
/// ```swift
/// extension MyArea {
///     @ItemEventHandler(.magicSword)
///     static let swordHandler = ItemEventHandler { engine, event in
///         // Handler logic
///     }
/// }
/// ```
@attached(peer)
public macro ItemEventHandler(_ itemID: ItemID) = #externalMacro(module: "GnustoMacros", type: "ItemEventHandlerMacro")

/// Marks a location event handler with automatic association to the specified location.
///
/// Usage:
/// ```swift
/// extension MyArea {
///     @LocationEventHandler(.throneRoom)
///     static let throneHandler = LocationEventHandler { engine, event in
///         // Handler logic
///     }
/// }
/// ```
@attached(peer)
public macro LocationEventHandler(_ locationID: LocationID) = #externalMacro(module: "GnustoMacros", type: "LocationEventHandlerMacro")

/// Marks a fuse definition with automatic ID generation and registration.
///
/// Usage:
/// ```swift
/// extension MyArea {
///     @GameFuse("hunger_timer")
///     static let hungerFuse = FuseDefinition(
///         turns: 10,
///         action: { engine in
///             // Fuse action
///         }
///     )
/// }
/// ```
@attached(peer)
public macro GameFuse(_ id: String) = #externalMacro(module: "GnustoMacros", type: "GameFuseMacro")

/// Marks a daemon definition with automatic ID generation and registration.
///
/// Usage:
/// ```swift
/// extension MyArea {
///     @GameDaemon("weather_system")
///     static let weatherDaemon = DaemonDefinition(
///         frequency: 5,
///         action: { engine in
///             // Daemon action
///         }
///     )
/// }
/// ```
@attached(peer)
public macro GameDaemon(_ id: String) = #externalMacro(module: "GnustoMacros", type: "GameDaemonMacro")

/// Compiler plugin registration
@main
struct GnustoMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GameBlueprintMacro.self,
        GameAreaMacro.self,
        GameItemMacro.self,
        GameLocationMacro.self,
        ItemEventHandlerMacro.self,
        LocationEventHandlerMacro.self,
        GameFuseMacro.self,
        GameDaemonMacro.self,
    ]
} 