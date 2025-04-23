import Foundation

@MainActor
public protocol GameDefinition {
    /// The complete state of the world at the start of the game.
    var state: GameState { get }
    
    /// The registry stores definitions for various game elements like Fuses, Daemons,
    /// and custom action handlers.
    var registry: GameDefinitionRegistry { get }

    /// Called when entering a new room.
    /// 
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var onEnterRoom: @MainActor @Sendable (GameEngine, LocationID) async -> Bool { get }

    /// Called before each turn.
    ///
    /// Returns `true` if no further action handling is required, otherwise `false`.
    var beforeTurn: @MainActor @Sendable (GameEngine, Command) async -> Bool { get }

    init()
}

// MARK: - Default implementations

extension GameDefinition {
    public var onEnterRoom: @MainActor @Sendable (GameEngine, LocationID) async -> Bool {
        { _, _ in false }
    }

    public var beforeTurn: @MainActor @Sendable (GameEngine, Command) async -> Bool {
        { _, _ in false }
    }
}
