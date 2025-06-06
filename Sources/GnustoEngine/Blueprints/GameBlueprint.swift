import Foundation

// MARK: - Compute Handler Type Aliases

public typealias ItemComputer = [AttributeID: ItemComputeHandler]

public typealias LocationComputer = [AttributeID: LocationComputeHandler]

/// A closure that dynamically computes the value of a specific item's attribute.
///
/// When the `GameEngine` needs the value of an item attribute for which a compute handler
/// is registered, it will invoke this closure.
///
/// - Parameters:
///   - item: The specific `Item` instance whose attribute is being computed.
///   - gameState: The current `GameState`, providing access to the entire game world state
///                for complex calculations (e.g., checking other items, player status, global flags).
/// - Returns: The computed `StateValue` for the attribute.
/// - Throws: An error if computation fails (though typically, computation should aim to be non-failing).
public typealias ItemComputeHandler = (@Sendable (Item, GameState) async throws -> StateValue)

/// A closure that dynamically computes the value of a specific location's attribute.
///
/// Similar to `ItemComputeHandler`, but for `Location` attributes.
///
/// - Parameters:
///   - location: The specific `Location` instance whose attribute is being computed.
///   - gameState: The current `GameState`.
/// - Returns: The computed `StateValue` for the attribute.
/// - Throws: An error if computation fails.
public typealias LocationComputeHandler = (@Sendable (Location, GameState) async throws -> StateValue)

/// Defines the foundational structure and core components of a Gnusto-powered game.
///
/// Implement this protocol to specify all the essential elements for your game, including
/// game-specific constants, custom behaviors, and event handlers.
///
/// The `GameEngine` uses this blueprint to build the initial `GameState` and configure the game.
///
/// For organizing game content (locations, items, and their specific event handlers), consider
/// grouping them into logical area structures (enums or structs). The definitions from these areas
/// can then be aggregated and provided to the relevant properties of your `GameBlueprint`
/// implementation (e.g., `items`, `locations`, `itemEventHandlers`, `locationEventHandlers`).
public protocol GameBlueprint: Sendable {
    /// The core metadata constants for the game.
    ///
    /// Provide an instance of `GameConstants` here, which includes details like
    /// the story title, introduction, release information, and maximum score.
    /// This information is often displayed to the player at the start of the game.
    var constants: GameConstants { get }

    /// An object representing the player character, containing their current status, inventory,
    /// score, location, etc.
    var player: Player { get }

    /// All items in the game world.
    ///
    /// This array defines all items that exist in the game, including their properties,
    /// initial locations, and other characteristics. The `GameEngine` uses this to
    /// build the initial `GameState`.
    var items: [Item] { get }

    /// All locations in the game world.
    ///
    /// This array defines all locations that exist in the game, including their
    /// descriptions, exits, and properties. The `GameEngine` uses this to
    /// build the initial `GameState`.
    var locations: [Location] { get }

    /// Optional closures to provide custom action handlers for specific verbs,
    /// overriding the default engine handlers.
    ///
    /// Use this dictionary to replace or augment the standard behavior for verbs
    /// like "take", "open", "go", etc. The key is a `VerbID` (e.g., `.take`) and
    /// the value is an `ActionHandler` implementation.
    ///
    /// The default implementation provides an empty dictionary, meaning all verbs
    /// will use their standard engine behaviors unless overridden.
    var customActionHandlers: [VerbID: ActionHandler] { get }

    /// Handlers triggered by events occurring for a specific item.
    ///
    /// This dictionary allows you to define custom logic that runs when certain
    /// events happen to specific items. The key is an `ItemID` and the value is
    /// an `ItemEventHandler`. Events include `beforeTurn` and `afterTurn`.
    ///
    /// The default implementation provides an empty dictionary.
    var itemEventHandlers: [ItemID: ItemEventHandler] { get }

    /// Handlers triggered by events occurring within a specific location.
    ///
    /// This dictionary allows you to define custom logic that runs when certain
    /// events happen within specific locations. The key is a `LocationID` and the value is
    /// a `LocationEventHandler`. Events include `beforeTurn`, `afterTurn`, and `onEnter`.
    ///
    /// The default implementation provides an empty dictionary.
    var locationEventHandlers: [LocationID: LocationEventHandler] { get }

    /// Definitions for timed events (fuses) that trigger after a set number of turns.
    ///
    /// Fuses are classic ZIL features used to implement delayed actions or events.
    /// For example, a fuse might be lit on a stick of dynamite, causing an explosion
    /// after a set number of turns, or a magical spell might wear off after a duration.
    ///
    /// The `GameEngine` uses these definitions to manage active fuses throughout the game.
    /// The key is a `FuseID` and the value is the corresponding `FuseDefinition`.
    ///
    /// The default implementation provides an empty dictionary.
    var fuseDefinitions: [FuseID: FuseDefinition] { get }

    /// Definitions for background processes (daemons) that run periodically.
    ///
    /// Daemons are classic ZIL features used to implement recurring game world events,
    /// NPC behaviors, or other processes that occur automatically without direct player
    /// command. For example, a daemon might make an NPC wander, cause a light source
    /// to gradually dim, or check if a certain game condition triggers a special event.
    ///
    /// The `GameEngine` uses these definitions to manage active daemons throughout the game.
    /// The key is a `DaemonID` and the value is the corresponding `DaemonDefinition`.
    ///
    /// The default implementation provides an empty dictionary.
    var daemonDefinitions: [DaemonID: DaemonDefinition] { get }

    /// Dynamic compute handlers for item attributes, organized by item and attribute.
    ///
    /// This allows you to define custom logic for computing item attributes at runtime.
    /// Each handler receives the `Item` instance and current `GameState`, returning
    /// a computed `StateValue`. Common use cases include dynamic descriptions that
    /// change based on game state, calculated properties, or conditional attributes.
    ///
    /// Example usage:
    /// ```swift
    /// var itemComputeHandlers: [ItemID: [AttributeID: ItemComputeHandler]] {
    ///     [
    ///         .magicSword: [
    ///             .description: { item, gameState in
    ///                 let enchantment = item.attributes["enchantmentLevel"]?.toInt ?? 0
    ///                 let desc = enchantment > 5 ? "A brilliantly glowing sword" : "A faintly shimmering blade"
    ///                 return .string(desc)
    ///             }
    ///         ]
    ///     ]
    /// }
    /// ```
    ///
    /// The default implementation provides an empty dictionary.
    var itemComputeHandlers: [ItemID: [AttributeID: ItemComputeHandler]] { get }

    /// Dynamic compute handlers for location attributes, organized by location and attribute.
    ///
    /// This allows you to define custom logic for computing location attributes at runtime.
    /// Each handler receives the `Location` instance and current `GameState`, returning
    /// a computed `StateValue`. Common use cases include dynamic descriptions that
    /// change based on game state, environmental conditions, or player actions.
    ///
    /// Example usage:
    /// ```swift
    /// var locationComputeHandlers: [LocationID: [AttributeID: LocationComputeHandler]] {
    ///     [
    ///         .magicRoom: [
    ///             .description: { location, gameState in
    ///                 let isEnchanted = gameState.globalState["roomEnchanted"] == true
    ///                 let desc = isEnchanted ? "The room sparkles with magical energy." : "The room appears ordinary."
    ///                 return .string(desc)
    ///             }
    ///         ]
    ///     ]
    /// }
    /// ```
    ///
    /// The default implementation provides an empty dictionary.
    var locationComputeHandlers: [LocationID: [AttributeID: LocationComputeHandler]] { get }
}

// MARK: - Default implementations

extension GameBlueprint {
    public var items: [Item] {
        []
    }

    public var locations: [Location] {
        []
    }

    public var customActionHandlers: [VerbID: ActionHandler] {
        [:]
    }

    public var itemEventHandlers: [ItemID: ItemEventHandler] {
        [:]
    }

    public var locationEventHandlers: [LocationID: LocationEventHandler] {
        [:]
    }

    public var fuseDefinitions: [FuseID: FuseDefinition] {
        [:]
    }

    public var daemonDefinitions: [DaemonID: DaemonDefinition] {
        [:]
    }

    public var itemComputeHandlers: [ItemID: [AttributeID: ItemComputeHandler]] {
        [:]
    }

    public var locationComputeHandlers: [LocationID: [AttributeID: LocationComputeHandler]] {
        [:]
    }
}
