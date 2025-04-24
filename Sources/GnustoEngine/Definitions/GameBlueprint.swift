import Foundation

@MainActor
public protocol GameBlueprint {
    /// The complete state of the world at the start of the game.
    var state: GameState { get }
    
    /// The registry stores definitions for various game elements like Fuses, Daemons,
    /// and custom action handlers.
    var registry: DefinitionRegistry { get }

    /// Called when entering a new room.
    /// 
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var onEnterRoom: @MainActor @Sendable (GameEngine, LocationID) async -> Bool { get }

    /// Called before each turn.
    ///
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var beforeTurn: @MainActor @Sendable (GameEngine, Command) async -> Bool { get }
}

// MARK: - Default implementations

extension GameBlueprint {
    public var onEnterRoom: @MainActor @Sendable (GameEngine, LocationID) async -> Bool {
        { _, _ in false }
    }

    public var beforeTurn: @MainActor @Sendable (GameEngine, Command) async -> Bool {
        { _, _ in false }
    }
}
