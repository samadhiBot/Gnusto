import Foundation

/// Defines the foundational structure and core components of a Gnusto-powered game.
///
/// Implement this protocol to specify all the essential elements for your game,
/// including initial world state, game-specific constants, custom behaviors, and event handlers.
/// The `GameEngine` uses this blueprint to initialize and run the game.
///
/// For organizing game content (locations, items, and their specific event handlers),
/// consider using types that conform to `AreaBlueprint`. The definitions from these
/// area blueprints can then be aggregated and provided to the relevant properties of
/// your `GameBlueprint` implementation (e.g., `state`, `itemEventHandlers`,
/// `locationEventHandlers`).
public protocol GameBlueprint: Sendable {
    /// The core metadata constants for the game.
    ///
    /// Provide an instance of `GameConstants` here, which includes details like
    /// the story title, introduction, release information, and maximum score.
    /// This information is often displayed to the player at the start of the game.
    var constants: GameConstants { get }

    /// The complete state of the world at the start of the game.
    ///
    /// This `GameState` instance defines all locations, items (and their properties),
    /// the initial player state, active timers (fuses and daemons), and any global
    /// variables at the moment the game begins.
    ///
    /// > Important: This property **only** defomes the state at the game's outset. Any later
    ///   mutations occur on a separate copy maintained by the ``GameEngine`` actor.
    var state: GameState { get }

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

    /// The registry containing definitions for timed events (fuses) and background
    /// processes (daemons).
    ///
    /// Use this to provide `FuseDefinition` and `DaemonDefinition` instances that
    /// the `GameEngine` will manage throughout the game. Fuses trigger an action
    /// after a set number of turns, while daemons run their action every turn they
    /// are active.
    ///
    /// The default implementation provides an empty `TimeRegistry`.
    var timeRegistry: TimeRegistry { get }

    /// The registry containing handlers for dynamically computing or validating
    /// item and location attributes.
    ///
    /// Provide a `DynamicAttributeRegistry` to define custom logic for how certain
    /// item or location attributes (like `description`, `name`, or custom flags)
    /// are calculated at runtime or to validate changes to their values.
    ///
    /// The default implementation provides an empty `DynamicAttributeRegistry`.
    var dynamicAttributeRegistry: DynamicAttributeRegistry { get }
}

// MARK: - Default implementations

extension GameBlueprint {
    public var customActionHandlers: [VerbID: ActionHandler] {
        [:]
    }

    public var itemEventHandlers: [ItemID: ItemEventHandler] {
        [:]
    }

    public var locationEventHandlers: [LocationID: LocationEventHandler] {
        [:]
    }

    public var timeRegistry: TimeRegistry {
        TimeRegistry()
    }

    public var dynamicAttributeRegistry: DynamicAttributeRegistry {
        DynamicAttributeRegistry()
    }
}
