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
@attached(extension, conformances: GameBlueprint)
public macro GameBlueprint(
    title: String,
    introduction: String,
    maxScore: Int,
    startingLocation: LocationID
) = #externalMacro(module: "GnustoMacros", type: "GameBlueprintMacro")

/// Marks a struct as a game area with automatic discovery of all content.
///
/// This macro:
/// 1. Scans all extensions of the marked type for `@GameItem`, `@GameLocation`, etc.
/// 2. Generates the complete `AreaBlueprint` conformance
/// 3. Auto-generates discovery functions for all content types
/// 4. Validates cross-references within the area
///
/// Usage:
/// ```swift
/// @GameArea
/// struct Act1Area {
///     // Content discovered automatically from extensions!
/// }
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: AreaBlueprint)
public macro GameArea() = #externalMacro(module: "GnustoMacros", type: "GameAreaMacro")

/// Marks a game item and auto-generates its ID constant.
///
/// Usage:
/// ```swift
/// @GameItem
/// static let magicSword = Item(.name("magic sword"))
/// // Generates: static let magicSwordID = ItemID("magicSword")
/// ```
@attached(peer, names: suffixed(ID))
public macro GameItem() = #externalMacro(module: "GnustoMacros", type: "GameItemMacro")

/// Marks a game location and auto-generates its ID constant.
///
/// Usage:
/// ```swift
/// @GameLocation
/// static let throneRoom = Location(.name("Throne Room"))
/// // Generates: static let throneRoomID = LocationID("throneRoom")
/// ```
@attached(peer, names: suffixed(ID))
public macro GameLocation() = #externalMacro(module: "GnustoMacros", type: "GameLocationMacro")

/// Marks an item event handler for automatic registration.
@attached(peer)
public macro ItemEventHandler(for itemID: ItemID) = #externalMacro(module: "GnustoMacros", type: "ItemEventHandlerMacro")

/// Marks a location event handler for automatic registration.
@attached(peer)
public macro LocationEventHandler(for locationID: LocationID) = #externalMacro(module: "GnustoMacros", type: "LocationEventHandlerMacro")

/// Marks a fuse definition for automatic registration.
@attached(peer)
public macro GameFuse() = #externalMacro(module: "GnustoMacros", type: "GameFuseMacro")

/// Marks a daemon definition for automatic registration.
@attached(peer)
public macro GameDaemon() = #externalMacro(module: "GnustoMacros", type: "GameDaemonMacro") 