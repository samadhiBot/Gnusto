import Foundation

/// Defines the blueprint for handling a specific game verb (e.g., "take", "open", "go").
///
/// Implement this protocol to create custom logic for how game actions are validated,
/// processed, and how their results are handled. The `GameEngine` uses `ActionHandler`
/// instances (provided via `GameBlueprint.customActionHandlers` or the engine's default
/// handlers) to execute parsed player `Command`s.
///
/// The handling of an action is divided into three distinct, asynchronous phases:
/// 1.  **`validate(context:)`**: Check if the action is currently possible (e.g., prerequisites met,
///     target item is accessible). This phase should *not* modify game state.
/// 2.  **`process(context:)`**: Execute the core logic of the action. This phase may involve
///     calculating intended state changes and determining the outcome (e.g., success message,
///     failure reason, side effects).
/// 3.  **`postProcess(context:result:)`**: Perform any cleanup or follow-up tasks after `process`
///     has completed. The engine typically applies state changes and prints messages *after*
///     `process` returns and *before* `postProcess` is called, but `postProcess` offers a hook
///     for additional logic if needed.
///
/// Handlers should be `Sendable` as they are used by the `GameEngine` actor.
public protocol ActionHandler: Sendable {
    /// Validates if the action can be performed based on the current game state and command context.
    ///
    /// This method should check all prerequisites for the action (e.g., is the target item held?
    /// Is the door unlocked? Does the player have the required tool?). It should *not* make
    /// any changes to the game state (`context.stateSnapshot` provides an immutable view for checks).
    ///
    /// If validation fails, this method should throw an appropriate `ActionResponse` (e.g.,
    /// `.itemNotHeld(itemID)`, `.itemIsLocked(itemID)`). If validation passes, it should return normally.
    ///
    /// - Parameters:
    ///   - context: An `ActionContext` providing the current `Command`, a non-isolated reference
    ///              to the `GameEngine`, an immutable `GameState` snapshot, and any additional
    ///              contextual data.
    /// - Throws: An `ActionResponse` if validation fails, preventing further processing.
    func validate(
        context: ActionContext
    ) async throws

    /// Processes the core logic of the action and determines its outcome.
    ///
    /// This method is called only if `validate(context:)` completed successfully. Here, you
    /// implement the primary effect of the action. This might involve:
    ///   - Creating `StateChange` objects to represent modifications to the game world.
    ///   - Defining `SideEffect`s (e.g., starting a timer, activating a daemon).
    ///   - Crafting a message to be displayed to the player.
    ///
    /// All outcomes are packaged into an `ActionResult`.
    ///
    /// - Parameters:
    ///   - context: The `ActionContext` (same as in `validate`).
    /// - Returns: An `ActionResult` detailing the outcome. This includes an optional message
    ///            for the player, an array of `StateChange`s to be applied by the engine, and
    ///            an array of `SideEffect`s to be triggered.
    /// - Throws: An `ActionResponse` or other `Error` if processing fails unexpectedly.
    ///           Throwing an `ActionResponse` here will typically result in its standard message
    ///           being shown to the player.
    func process(
        context: ActionContext
    ) async throws -> ActionResult

    /// Handles any follow-up effects or cleanup after the `process` step has completed
    /// and its `ActionResult` has been initially handled by the engine.
    ///
    /// The `GameEngine` usually applies `StateChange`s and prints the primary message from
    /// the `ActionResult` *before* calling this method. `postProcess` provides an opportunity
    /// for actions that need to occur after these main effects, such as printing additional
    /// messages, triggering sounds, or performing complex state updates that depend on the
    /// just-applied changes. The default implementation of this method does nothing.
    ///
    /// - Parameters:
    ///   - context: The `ActionContext` (same as in `validate` and `process`).
    ///   - result: The `ActionResult` that was returned by the `process` step.
    /// - Throws: An `Error` if post-processing encounters a problem. This is generally
    ///           less common than throwing from `validate` or `process`.
    func postProcess(
        context: ActionContext,
        result: ActionResult
    ) async throws
}

// MARK: - Default Implementation

extension ActionHandler {
    /// Default implementation for `validate`. Does nothing, assuming the action is always valid
    /// unless overridden by a specific handler.
    public func validate(
        context: ActionContext
    ) async throws {
        // Default: No specific validation required.
    }

    /// Default implementation for `postProcess`. Does nothing.
    ///
    /// This optional step allows handlers to implement custom logic that should execute
    /// after the `process` method returns its `ActionResult`, and after the `GameEngine`
    /// has applied the primary state changes and printed the main message from that result.
    /// Most handlers may not need to override this.
    public func postProcess(
        context: ActionContext,
        result: ActionResult
    ) async throws {
        // Default: Do nothing
    }
}
