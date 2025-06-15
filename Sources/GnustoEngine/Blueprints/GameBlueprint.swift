import Foundation

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
    var fuses: [FuseID: FuseDefinition] { get }

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
    var daemons: [DaemonID: DaemonDefinition] { get }

    /// Custom compute handlers for dynamic item attributes.
    ///
    /// Compute handlers allow items to have attributes that are calculated dynamically
    /// based on game state rather than stored as static values.
    ///
    /// Example:
    /// ```swift
    /// var itemComputers: [ItemID: ItemComputer] {
    ///     return [
    ///         .magicSword: ItemComputer { attributeID, gameState in
    ///             switch attributeID {
    ///             case .description:
    ///                 let enchantment = try gameState.value(of: .enchantmentLevel, on: .magicSword) ?? 0
    ///                 return .string(enchantment > 5 ? "Blazing sword!" : "Glowing blade")
    ///             default:
    ///                 return nil
    ///             }
    ///         }
    ///     ]
    /// }
    /// ```
    var itemComputers: [ItemID: ItemComputer] { get }

    /// Custom compute handlers for dynamic location attributes.
    ///
    /// Compute handlers allow locations to have attributes that are calculated dynamically
    /// based on game state rather than stored as static values.
    ///
    /// Example:
    /// ```swift
    /// var locationComputers: [LocationID: LocationComputer] {
    ///     return [
    ///         .enchantedForest: LocationComputer { attributeID, gameState in
    ///             switch attributeID {
    ///             case .description:
    ///                 let timeOfDay = try gameState.value(of: .timeOfDay) ?? "day"
    ///                 return .string(timeOfDay == "night" ? "Dark woods loom." : "Sunlight filters through trees.")
    ///             default:
    ///                 return nil
    ///             }
    ///         }
    ///     ]
    /// }
    /// ```
    var locationComputers: [LocationID: LocationComputer] { get }

    /// The message provider for game text localization and customization.
    ///
    /// This provider supplies all user-facing messages throughout the game, including
    /// action responses, parse errors, and system messages. Games can provide custom
    /// implementations to:
    /// - Support multiple languages (internationalization)
    /// - Customize the tone and style of responses
    /// - Override specific messages while inheriting sensible defaults
    ///
    /// If not specified, the engine will use `StandardMessageProvider` with traditional
    /// English interactive fiction responses.
    ///
    /// Example:
    /// ```swift
    /// var messageProvider: MessageProvider {
    ///     // Custom provider for a horror-themed game
    ///     HorrorMessageProvider()
    /// }
    /// ```
    var messageProvider: MessageProvider { get }

    /// A random number generator used throughout the game for various randomization needs.
    ///
    /// This generator is used for determining random events, NPC behaviors, game mechanics,
    /// and other probabilistic elements. The default implementation uses the system's
    /// random number generator.
    ///
    /// For testing purposes, you can provide a custom implementation that returns
    /// predetermined values to ensure consistent test results.
    ///
    /// Example:
    /// ```swift
    /// var randomNumberGenerator: any RandomNumberGenerator {
    ///     // For testing: return a fixed value generator
    ///     FixedRandomNumberGenerator(value: 0.5)
    /// }
    /// ```
    var randomNumberGenerator: any RandomNumberGenerator { get }
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

    public var fuses: [FuseID: FuseDefinition] {
        [:]
    }

    public var daemons: [DaemonID: DaemonDefinition] {
        [:]
    }

    public var itemComputers: [ItemID: ItemComputer] {
        [:]
    }

    public var locationComputers: [LocationID: LocationComputer] {
        [:]
    }

    public var messageProvider: MessageProvider {
        MessageProvider()
    }

    public var randomNumberGenerator: any RandomNumberGenerator {
        SystemRandomNumberGenerator()
    }
}
