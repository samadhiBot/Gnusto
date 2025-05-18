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

/// A protocol for objects that can generate or augment an `ActionContext` with
/// additional game-specific information before an action is handled.
///
/// The `GameEngine` provides a foundational `ActionContext`. If your game's actions
/// require more detailed or dynamically calculated context (e.g., the mood of an NPC,
/// the result of a recent mini-game), you can implement this protocol.
///
/// An `ActionContextProvider` takes the initial `ActionContext` (which includes the
/// `Command`, `GameEngine` reference, and `GameState` snapshot) and can return
/// a new or modified `ActionContext`, typically by adding custom data to its
/// `contextData` dictionary. This enriched context is then passed to the
/// relevant `ActionHandler`.
public protocol ActionContextProvider: Sendable {
    /// Generates or augments an `ActionContext` with additional information.
    ///
    /// Implement this method to gather any extra data your game needs for a specific
    /// action and incorporate it into the `ActionContext`. You can use the provided
    /// `context` to access the current `Command`, `GameEngine`, and `GameState` snapshot.
    ///
    /// - Parameter context: The initial `ActionContext` provided by the engine.
    ///   This context contains the `command` being processed, a reference to the
    ///   `engine`, and a `stateSnapshot`.
    /// - Returns: An `ActionContext`, which may be the original context augmented with
    ///   new `contextData`, or an entirely new `ActionContext` instance if necessary.
    /// - Throws: An error if the required contextual information cannot be generated.
    func getContext(for context: ActionContext) async throws -> ActionContext
}
