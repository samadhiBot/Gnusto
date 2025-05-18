import Foundation

/// Provides comprehensive contextual information for the execution of a game action.
///
/// An `ActionContext` instance is passed to each method of an `ActionHandler`
/// (`validate`, `process`, `postProcess`). It serves as a container for all data
/// relevant to the current action, allowing handlers to make informed decisions and
/// to interact with the game world.
public struct ActionContext: Sendable {
    /// The specific `Command` (parsed from player input) that is currently being executed.
    /// This includes the verb, direct/indirect objects, modifiers, etc.
    public let command: Command

    /// A non-isolated reference to the `GameEngine` instance.
    ///
    /// Through this, action handlers can query the current game state (though using
    /// `stateSnapshot` is often preferred for consistency within a single handler phase),
    /// create `StateChange` objects, or call other engine utilities. Accessing methods or
    /// properties on `engine` requires `await` due to its actor nature.
    nonisolated public let engine: GameEngine

    /// An immutable snapshot of the `GameState` taken at the beginning of the current
    /// action's processing.
    ///
    /// Handlers should primarily use this snapshot for checks and decisions within a single
    /// phase (e.g., `validate`) to ensure consistency, as the live `engine.gameState`
    /// might change due to other concurrent activities (though less common in typical
    /// turn-based IF).
    public let stateSnapshot: GameState

    /// A dictionary for game-specific or handler-specific additional data that doesn't fit
    /// neatly into the other properties.
    ///
    /// Keys are `ContextID`s for type safety, and values are `StateValue`s.
    /// This can be used to pass arbitrary information to an action handler if needed
    /// by a particular game's design.
    public let contextData: [ContextID: StateValue]

    /// Initializes a new `ActionContext`.
    ///
    /// This is typically called by the `GameEngine` or an `ActionContextProvider` before
    /// invoking an `ActionHandler`.
    ///
    /// - Parameters:
    ///   - command: The `Command` being executed.
    ///   - engine: The `GameEngine` instance.
    ///   - stateSnapshot: An immutable snapshot of the `GameState`.
    ///   - contextData: Optional game-specific data for the handler.
    public init(
        command: Command,
        engine: GameEngine,
        stateSnapshot: GameState,
        contextData: [ContextID: StateValue] = [:]
    ) {
        self.command = command
        self.engine = engine
        self.stateSnapshot = stateSnapshot
        self.contextData = contextData
    }
}

/// A protocol for objects capable of generating or augmenting an `ActionContext`
/// for a given command.
///
/// While the `GameEngine` provides a basic `ActionContext`, some games or complex actions
/// might require additional, specific context. Implementations of this protocol can be used
/// to gather this extra information and add it to the `contextData` field of an
/// `ActionContext` before it is passed to an `ActionHandler`.
///
/// (Note: The current `getContext` method signature seems to take an existing context
/// and return a new one. This might be intended for chaining context providers or augmenting
/// an initial context provided by the engine.)
public protocol ActionContextProvider: Sendable {
    /// Creates or augments context information relevant to the specified command and existing context.
    ///
    /// - Parameters:
    ///   - command: The `Command` being executed (available via `context.command`).
    ///   - engine: The `GameEngine` instance (available via `context.engine`).
    ///   - context: The current `ActionContext` which may be augmented or used to create a new one.
    /// - Returns: An `ActionContext` instance, potentially enriched with more data.
    /// - Throws: An error if context generation or augmentation fails.
        func getContext(for context: ActionContext) async throws -> ActionContext
}
