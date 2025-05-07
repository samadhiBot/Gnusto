import Foundation

public protocol GameBlueprint: Sendable {
    /// The complete state of the world at the start of the game.
    var state: GameState { get }

    /// The registry containing definitions for fuses, daemons, and action overrides.
    var definitionRegistry: DefinitionRegistry { get }

    /// The registry containing dynamic property handlers (compute/validate).
    var dynamicAttributeRegistry: DynamicAttributeRegistry { get }

    /// Called when entering a new room.
    ///
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var onEnterRoom: @Sendable (GameEngine, LocationID) async -> Bool { get }

    /// Called before each turn.
    ///
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var beforeTurn: @Sendable (GameEngine, Command) async -> Bool { get }
}

// MARK: - Default implementations

extension GameBlueprint {
    public var onEnterRoom: @Sendable (GameEngine, LocationID) async -> Bool {
        { _, _ in false }
    }

    public var beforeTurn: @Sendable (GameEngine, Command) async -> Bool {
        { _, _ in false }
    }
}
