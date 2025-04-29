import Foundation

/// Enhanced `ActionHandler` protocol with distinct validation, processing, and post-processing steps.
///
/// This protocol provides a more structured way to handle complex actions that involve
/// multiple stages or potential side effects.
/// Note: This protocol is Sendable as its methods now use Sendable types.
public protocol EnhancedActionHandler: Sendable {
    /// Validates if the action can be performed given the current game state.
    /// This step should check prerequisites but not modify the game state.
    /// - Parameters:
    ///   - command: The parsed player command.
    ///   - engine: The game engine instance.
    /// - Throws: An `ActionError` if validation fails.
    func validate(
        command: Command,
        engine: GameEngine
    ) async throws

    /// Processes the core logic of the action and determines the outcome.
    /// This step may modify the game state temporarily or calculate intended changes.
    /// - Parameters:
    ///   - command: The parsed player command.
    ///   - engine: The game engine instance.
    /// - Returns: An `ActionResult` detailing the outcome, including success status, messages, state changes, and side effects.
    /// - Throws: An `ActionError` or other error if processing fails unexpectedly.
    func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult

    /// Handles any follow-up effects after the action has been processed.
    /// This step applies the state changes and triggers side effects defined in the `ActionResult`.
    /// It might also handle displaying messages to the player.
    /// - Parameters:
    ///   - command: The parsed player command.
    ///   - engine: The game engine instance.
    ///   - result: The `ActionResult` returned by the `process` step.
    /// - Throws: An error if post-processing fails.
    func postProcess(
        command: Command,
        engine: GameEngine,
        result: ActionResult
    ) async throws
}

// MARK: - Default Implementation

extension EnhancedActionHandler {
    /// Default implementation of the original `ActionHandler.perform` method.
    /// This bridges the old `perform` requirement to the new pipeline (`validate`, `process`, `postProcess`).
    /// Simple action handlers can continue using the old `perform` method if they don't need the enhanced pipeline.
    public func perform(
        command: Command,
        engine: GameEngine
    ) async throws {
        try await validate(command: command, engine: engine)
        let result = try await process(command: command, engine: engine)
        // TODO: Consider if the engine should apply state changes/side effects centrally
        // based on ActionResult, or if the handler's postProcess is always responsible.
        // For now, assume postProcess handles applying the result.
        try await postProcess(command: command, engine: engine, result: result)
    }

    // Provide default empty implementations for validate and postProcess
    // to make adoption easier for handlers that only need custom process logic.

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // Default: No specific validation required.
    }

    public func postProcess(
        command: Command,
        engine: GameEngine,
        result: ActionResult
    ) async throws {
        // Default: Print the message from the result, regardless of success.
        // The message often indicates *why* an action failed (e.g., "You already have that.").
        // State changes and side effects are assumed to be handled elsewhere or by the engine.
        if !result.message.isEmpty {
            await engine.ioHandler.print(result.message)
        }
        // TODO: Revisit if explicit error throwing is preferred over success=false + message.
    }
}

// MARK: - Associated Types & Aliases

/// A closure that handles a specific action potentially targeting a specific item.
/// Return `true` if the action was fully handled (preventing default verb handler), `false` otherwise.
public typealias ObjectActionHandler = @MainActor @Sendable (GameEngine, Command) async throws -> Bool
