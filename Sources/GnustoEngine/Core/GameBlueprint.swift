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
    /// The full title of the game (e.g., "ZORK I: The Great Underground Empire").
    /// This is typically displayed by the `GameEngine` when the game starts.
    var title: String { get }

    /// A shortened version of the title for use in file names and system identifiers.
    /// This should be a brief, filesystem-safe identifier derived from the full title
    /// (e.g., "Zork1" for "ZORK I: The Great Underground Empire", or "AMFV" for
    /// "A Mind Forever Voyaging"). Used for save game files, transcripts, and other
    /// file system operations where a concise identifier is needed.
    var abbreviatedTitle: String { get }

    /// An introductory text, often including a brief premise, version information, or byline.
    /// This is displayed by the `GameEngine` after the `title` when the game starts.
    var introduction: String { get }

    /// A version or release identifier for the game (e.g., "Release 1 / Serial number 880720").
    /// This can be part of the `introduction` or used separately as needed.
    var release: String { get }

    /// The maximum achievable score in the game. This is used by score-reporting actions
    /// and can be used by the game to determine if the player has "won".
    var maximumScore: Int { get }

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

    /// Custom action handlers that provide both verb definitions and logic.
    ///
    /// Each `ActionHandler` is self-contained, defining its own `verbID`, `syntax`,
    /// `synonyms`, and `requiresLight` properties along with the action logic.
    /// This eliminates the need to coordinate verb definitions across multiple files.
    ///
    /// Example:
    /// ```swift
    /// var customActionHandlers: [ActionHandler] {
    ///     [
    ///         SpellcastActionHandler(), // Defines .spellcast verb with custom syntax
    ///         CustomTakeHandler(),      // Overrides default .take behavior
    ///     ]
    /// }
    /// ```
    ///
    /// Custom handlers will override any default engine handlers with the same `verbID`.
    /// The default implementation provides an empty array.
    var customActionHandlers: [ActionHandler] { get }

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

    /// Combat systems for specific characters.
    ///
    /// This dictionary allows you to define custom combat behavior for specific characters
    /// in your game. The key is an `ItemID` (representing a character) and the value is
    /// a `CombatSystem` that defines how combat with that character works.
    ///
    /// Characters without registered combat systems will use the default combat system
    /// with standard parameters.
    ///
    /// Example:
    /// ```swift
    /// var combatSystems: [ItemID: any CombatSystem] {
    ///     [
    ///         .troll: TrollCombatSystem(),
    ///         .dragon: DragonCombatSystem(breathWeapon: .fire)
    ///     ]
    /// }
    /// ```
    ///
    /// The default implementation provides an empty dictionary.
    var combatSystems: [ItemID: any CombatSystem] { get }

    /// Combat messengers for specific characters or global combat messaging.
    ///
    /// This dictionary allows you to define custom combat messaging for specific characters
    /// in your game. The key is an `ItemID` (representing a character) and the value is
    /// a `CombatMessenger` that provides custom combat event descriptions.
    ///
    /// Characters without registered combat messengers will use the default combat messenger.
    /// You can also provide a default combat messenger by implementing `defaultCombatMessenger`.
    ///
    /// Example:
    /// ```swift
    /// var combatMessengers: [ItemID: CombatMessenger] {
    ///     [
    ///         .troll: TrollCombatMessenger(),
    ///         .dragon: DragonCombatMessenger()
    ///     ]
    /// }
    /// ```
    ///
    /// The default implementation provides an empty dictionary.
    var combatMessengers: [ItemID: CombatMessenger] { get }

    /// The default combat messenger used when no character-specific messenger is configured.
    ///
    /// This provides the base combat messaging system for all combat encounters unless
    /// overridden by a character-specific messenger in `combatMessengers`.
    ///
    /// Example:
    /// ```swift
    /// var defaultCombatMessenger: CombatMessenger {
    ///     CustomCombatMessenger(randomNumberGenerator: randomNumberGenerator)
    /// }
    /// ```
    ///
    /// The default implementation creates a standard `CombatMessenger`.
    var defaultCombatMessenger: CombatMessenger { get }

    /// Definitions for timed events (fuses) that trigger after a set number of turns.
    ///
    /// Fuses are classic ZIL features used to implement delayed actions or events.
    /// For example, a fuse might be lit on a stick of dynamite, causing an explosion
    /// after a set number of turns, or a magical spell might wear off after a duration.
    ///
    /// The `GameEngine` uses these definitions to manage active fuses throughout the game.
    /// The key is a `FuseID` and the value is the corresponding `Fuse`.
    ///
    /// The default implementation provides an empty dictionary.
    var fuses: [FuseID: Fuse] { get }

    /// Definitions for background processes (daemons) that run periodically.
    ///
    /// Daemons are classic ZIL features used to implement recurring game world events,
    /// NPC behaviors, or other processes that occur automatically without direct player
    /// command. For example, a daemon might make an NPC wander, cause a light source
    /// to gradually dim, or check if a certain game condition triggers a special event.
    ///
    /// The `GameEngine` uses these definitions to manage active daemons throughout the game.
    /// The key is a `DaemonID` and the value is the corresponding `Daemon`.
    ///
    /// The default implementation provides an empty dictionary.
    var daemons: [DaemonID: Daemon] { get }

    /// Custom compute handlers for dynamic item properties.
    ///
    /// Compute handlers allow items to have properties that are calculated dynamically
    /// based on game state rather than stored as static values.
    ///
    /// Example:
    /// ```swift
    /// var itemComputers: [ItemID: ItemComputer] {
    ///     return [
    ///         .magicSword: ItemComputer { propertyID, gameState in
    ///             switch propertyID {
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

    /// Custom compute handlers for dynamic location properties.
    ///
    /// Compute handlers allow locations to have properties that are calculated dynamically
    /// based on game state rather than stored as static values.
    ///
    /// Example:
    /// ```swift
    /// var locationComputers: [LocationID: LocationComputer] {
    ///     return [
    ///         .enchantedForest: LocationComputer { propertyID, gameState in
    ///             switch propertyID {
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
    /// If not specified, the engine will use the built-in `MessageProvider` with traditional
    /// English interactive fiction responses.
    ///
    /// **Testing Note**: Custom `MessageProvider` subclasses should accept a
    /// `RandomNumberGenerator` parameter in their initializer to support deterministic
    /// testing via `withSeededRNG()`. The default implementation automatically uses
    /// the blueprint's `randomNumberGenerator`.
    ///
    /// Example:
    /// ```swift
    /// var messenger: StandardMessenger {
    ///     // Custom messenger for a horror-themed game
    ///     HorrorMessenger(randomNumberGenerator: randomNumberGenerator)
    /// }
    /// ```
    var messenger: StandardMessenger { get }

    /// The random number generator used throughout the game for various randomization needs.
    ///
    /// This generator is used by the `Messenger` for selecting random responses,
    /// and can be used by custom game logic for probabilistic events, NPC behaviors,
    /// and other randomized mechanics.
    ///
    /// For testing purposes, provide a `SeededRandomNumberGenerator` to ensure
    /// consistent, reproducible results across test runs.
    ///
    /// Example:
    /// ```swift
    /// var randomNumberGenerator: any RandomNumberGenerator {
    ///     SeededRandomNumberGenerator(seed: 12345)
    /// }
    /// ```
    var randomNumberGenerator: any RandomNumberGenerator & Sendable { get }
}

// MARK: - Default implementations

extension GameBlueprint {
    public var locations: [Location] {
        []
    }

    public var customActionHandlers: [ActionHandler] {
        []
    }

    public var itemEventHandlers: [ItemID: ItemEventHandler] {
        [:]
    }

    public var locationEventHandlers: [LocationID: LocationEventHandler] {
        [:]
    }

    public var combatSystems: [ItemID: any CombatSystem] {
        [:]
    }

    public var combatMessengers: [ItemID: CombatMessenger] {
        [:]
    }

    public var defaultCombatMessenger: CombatMessenger {
        CombatMessenger(randomNumberGenerator: randomNumberGenerator)
    }

    public var fuses: [FuseID: Fuse] {
        [:]
    }

    public var daemons: [DaemonID: Daemon] {
        [:]
    }

    public var itemComputers: [ItemID: ItemComputer] {
        [:]
    }

    public var locationComputers: [LocationID: LocationComputer] {
        [:]
    }

    public var randomNumberGenerator: any RandomNumberGenerator & Sendable {
        SystemRandomNumberGenerator()
    }

    public var messenger: StandardMessenger {
        StandardMessenger()
    }
}
