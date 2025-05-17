import Foundation

public protocol GameBlueprint: Sendable {
    /// The core metadata constants for the game.
    var constants: GameConstants { get }

    /// The complete state of the world at the start of the game.
    var state: GameState { get }

    /// Optional closures to provide custom action handlers for specific verbs,
    /// overriding the default engine handlers.
    var customActionHandlers: [VerbID: ActionHandler] { get }

    /// Handlers triggered when an action targets a specific item ID.
    var itemEventHandlers: [ItemID: ItemEventHandler] { get }

    /// Handlers triggered by events occurring within a specific location ID.
    var locationEventHandlers: [LocationID: LocationEventHandler] { get }

    /// Called when entering a new room.
    ///
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var onEnterRoom: @Sendable (GameEngine, LocationID) async -> Bool { get }

    /// Called before each turn.
    ///
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var beforeTurn: @Sendable (GameEngine, Command) async -> Bool { get }

    /// The registry containing definitions for fuses, daemons, and action overrides.
    var definitionRegistry: DefinitionRegistry { get }

    /// The registry containing dynamic property handlers (compute/validate).
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

    public var onEnterRoom: @Sendable (GameEngine, LocationID) async -> Bool {
        { _, _ in false }
    }

    public var beforeTurn: @Sendable (GameEngine, Command) async -> Bool {
        { _, _ in false }
    }

    public var definitionRegistry: DefinitionRegistry {
        DefinitionRegistry()
    }

    public var dynamicAttributeRegistry: DynamicAttributeRegistry {
        DynamicAttributeRegistry()
    }
}
