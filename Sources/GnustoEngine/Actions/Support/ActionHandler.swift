import Foundation

/// Defines the protocol for objects that can handle specific game actions.
public protocol ActionHandler: Sendable {
    /// Executes the action logic.
    /// - Parameters:
    ///   - command: The parsed player command.
    ///   - engine: The game engine instance for accessing and modifying game state.
    /// - Throws: `ActionError` if the action cannot be performed.
    func perform(command: Command, engine: GameEngine) async throws
}

/// A closure that handles a specific action potentially targeting a specific item.
/// Return `true` if the action was fully handled (preventing default verb handler), `false` otherwise.
public typealias ObjectActionHandler = @MainActor @Sendable (GameEngine, Command) async throws -> Bool
