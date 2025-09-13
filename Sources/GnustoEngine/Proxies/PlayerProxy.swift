import Foundation

/// A lightweight proxy that provides dynamic property access for the player character through the GameEngine.
///
/// `PlayerProxy` wraps a `Player` and `GameEngine` reference, ensuring all property access
/// goes through the engine's state management system. This provides a consistent interface
/// for accessing player properties like inventory, location, score, and health.
///
/// Use `PlayerProxy` in action handlers and game logic instead of accessing the raw `Player`
/// struct directly to ensure proper state synchronization and dynamic property resolution.
public struct PlayerProxy: Sendable {
    /// The player character this proxy represents.
    let player: Player

    /// The game engine used for dynamic property resolution and state management.
    let engine: GameEngine

    /// Creates a new PlayerProxy for the game's player character.
    ///
    /// - Parameter gameEngine: The game engine to use for state access and dynamic resolution.
    init(with gameEngine: GameEngine) async {
        self.player = await gameEngine.gameState.player
        self.engine = gameEngine
    }
}

// MARK: - Convenience Extensions

extension GameEngine {
    /// Creates a `PlayerProxy` for the game's player character.
    ///
    /// This computed property provides convenient access to a proxy object that wraps
    /// the current player state and provides dynamic property resolution through the engine.
    ///
    /// - Returns: A `PlayerProxy` instance for dynamic property access.
    public var player: PlayerProxy {
        get async {
            await PlayerProxy(with: self)
        }
    }
}

// MARK: - Conformances

extension PlayerProxy: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(player)
    }

    public static func == (lhs: PlayerProxy, rhs: PlayerProxy) -> Bool {
        lhs.player == rhs.player
    }
}
