import Foundation

/// Defines the requirements for an object that handles the execution of a specific verb command.
// Removed @MainActor - Isolation handled by GameEngine/IOHandler calls
public protocol ActionHandler: Sendable {

    /// Performs the action associated with the command.
    ///
    /// Implementations should:
    /// 1. Validate preconditions (e.g., is the object takable? is the container open?).
    /// 2. Modify the `engine.gameState` if validation passes.
    /// 3. Use `engine.ioHandler` to print appropriate messages to the player.
    /// 4. Throw an `ActionError` if a precondition fails or an execution error occurs.
    ///
    /// - Parameters:
    ///   - command: The parsed command to execute.
    ///   - engine: A reference to the `GameEngine` to access game state and I/O.
    /// - Throws: An `ActionError` if the action cannot be performed.
    func perform(command: Command, engine: GameEngine) async throws
}
