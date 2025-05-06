import Foundation

/// Provides contextual information relevant to the execution of a specific action.
///
/// This struct aggregates data beyond the basic command and engine instance,
/// potentially including details about the target objects, environment state,
/// or specific conditions relevant to the action handler.
public struct ActionContext: Sendable {
    /// The command being executed.
    public let command: Command

    /// The game engine instance.
    /// Note: This is non-isolated. Accessing engine properties/methods requires `await`.
    nonisolated public let engine: GameEngine

    /// A snapshot of the game state at the time the context was created.
    /// Handlers should rely on this snapshot for consistent checks, rather than
    /// repeatedly querying the potentially changing `engine.gameState`.
    public let stateSnapshot: GameState

    /// Game-specific or handler-specific additional data.
    /// Keys use `ContextID` for type safety, values use `StateValue`.
    public let contextData: [ContextID: StateValue]

    /// Initializes the action context.
    ///
    /// Typically created by an `ActionContextProvider`.
    public init(
        command: Command,
        engine: GameEngine,
        stateSnapshot: GameState,
        contextData: [ContextID: StateValue] = [:] // Use ContextID
    ) {
        self.command = command
        self.engine = engine
        self.stateSnapshot = stateSnapshot
        self.contextData = contextData
    }
}

/// A protocol for objects capable of generating an `ActionContext` for a given command.
///
/// Implementations can gather relevant state and information based on the command
/// and provide it in a structured way to action handlers.
public protocol ActionContextProvider: Sendable {
    /// Creates context information relevant to the specified command.
    ///
    /// - Parameters:
    ///   - command: The command being executed.
    ///   - engine: The game engine instance.
    /// - Returns: An `ActionContext` instance.
    /// - Throws: An error if context generation fails.
    @MainActor
    func getContext(for context: ActionContext) async throws -> ActionContext
}
