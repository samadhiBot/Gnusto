import Foundation

// MARK: - Compute Handler Errors

/// Errors that can occur during attribute computation.
public enum ComputeError: Error, Sendable {
    /// The compute handler doesn't handle the requested attribute.
    case attributeNotHandled(AttributeID)

    /// A custom computation error with a descriptive message.
    case computationFailed(String)
}

// MARK: - Compute Handler Type Aliases

/// A compute handler for dynamic item attributes.
///
/// Similar to `ItemEventHandler`, this provides a single handler per item that can compute
/// dynamic values for multiple attributes based on the current game state.
public struct ItemComputer: Sendable {
    /// The compute function that calculates attribute values dynamically.
    ///
    /// - Parameters:
    ///   - item: The item whose attribute is being computed
    ///   - attributeID: The specific attribute being requested
    ///   - gameState: The current game state for context
    /// - Returns: The computed value for the attribute, or throws if computation fails
    public let compute: @Sendable (Item, AttributeID, GameState) async throws -> StateValue

    /// Creates a new item computer with the given compute function.
    public init(compute: @escaping @Sendable (Item, AttributeID, GameState) async throws -> StateValue) {
        self.compute = compute
    }
}

/// A compute handler for dynamic location attributes.
///
/// Similar to `LocationEventHandler`, this provides a single handler per location that can compute
/// dynamic values for multiple attributes based on the current game state.
public struct LocationComputer: Sendable {
    /// The compute function that calculates attribute values dynamically.
    ///
    /// - Parameters:
    ///   - location: The location whose attribute is being computed
    ///   - attributeID: The specific attribute being requested
    ///   - gameState: The current game state for context
    /// - Returns: The computed value for the attribute, or throws if computation fails
    public let compute: @Sendable (Location, AttributeID, GameState) async throws -> StateValue

    /// Creates a new location computer with the given compute function.
    public init(compute: @escaping @Sendable (Location, AttributeID, GameState) async throws -> StateValue) {
        self.compute = compute
    }
}



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

    /// Dynamic compute handlers for item attributes.
    ///
    /// This allows you to define custom logic for computing item attributes at runtime.
    /// Each handler receives the `Item` instance, the specific `AttributeID` being requested,
    /// and current `GameState`, returning a computed `StateValue`. This follows the same
    /// pattern as event handlers - one handler per item that can handle multiple attributes.
    ///
    /// Example usage:
    /// ```swift
    /// var itemComputers: [ItemID: ItemComputer] {
    ///     [
    ///         .magicSword: ItemComputer { item, attributeID, gameState in
    ///             switch attributeID {
    ///             case .description:
    ///                 let enchantment = item.attributes["enchantmentLevel"]?.toInt ?? 0
    ///                 let desc = enchantment > 5 ? "A brilliantly glowing sword" : "A faintly shimmering blade"
    ///                 return .string(desc)
    ///             default:
    ///                 throw ComputeError.attributeNotHandled(attributeID)
    ///             }
    ///         }
    ///     ]
    /// }
    /// ```
    ///
    /// The default implementation provides an empty dictionary.
    var itemComputers: [ItemID: ItemComputer] { get }

    /// Dynamic compute handlers for location attributes.
    ///
    /// This allows you to define custom logic for computing location attributes at runtime.
    /// Each handler receives the `Location` instance, the specific `AttributeID` being requested,
    /// and current `GameState`, returning a computed `StateValue`. This follows the same
    /// pattern as event handlers - one handler per location that can handle multiple attributes.
    ///
    /// Example usage:
    /// ```swift
    /// var locationComputers: [LocationID: LocationComputer] {
    ///     [
    ///         .magicRoom: LocationComputer { location, attributeID, gameState in
    ///             switch attributeID {
    ///             case .description:
    ///                 let isEnchanted = gameState.globalState["roomEnchanted"] == true
    ///                 let desc = isEnchanted ? "The room sparkles with magical energy." : "The room appears ordinary."
    ///                 return .string(desc)
    ///             default:
    ///                 throw ComputeError.attributeNotHandled(attributeID)
    ///             }
    ///         }
    ///     ]
    /// }
    /// ```
    ///
    /// The default implementation provides an empty dictionary.
    var locationComputers: [LocationID: LocationComputer] { get }
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

    public var itemComputers: [ItemID: ItemComputer] {
        [:]
    }

    public var locationComputers: [LocationID: LocationComputer] {
        [:]
    }
}
