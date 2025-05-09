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
    /// A convenience method that runs the validation and processing steps.
    ///
    /// Primarily intended as a convenience for testing handlers directly.
    ///
    /// Note: This default implementation does *not* apply the state changes from the returned
    ///       `ActionResult`, as that is the responsibility of the `GameEngine`.
    ///
    /// - Parameters:
    ///   - command: The command to perform.
    ///   - engine: The game engine instance.
    /// - Returns: The `ActionResult` produced by the `process` method.
    @discardableResult
    public func perform(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        try await validate(command: command, engine: engine)
        let result = try await process(command: command, engine: engine)
        // The GameEngine is responsible for applying state changes from the result.
        // The `postProcess` hook is available for handlers needing custom logic *after* processing.
        return result
    }

    public func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // Default: No specific validation required.
    }

    /// Optional step for handlers needing custom logic after `process` returns, but before
    /// the engine applies state changes or prints the message.
    ///
    /// The default implementation does nothing.
    public func postProcess(
        command: Command,
        engine: GameEngine,
        result: ActionResult
    ) async throws {
        // Default: Do nothing
    }
}

// MARK: - Associated Types & Aliases

/// A closure that handles a specific action potentially targeting a specific item.
/// Return `true` if the action was fully handled (preventing default verb handler), `false` otherwise.
public typealias ObjectActionHandler = @MainActor @Sendable (GameEngine, Command) async throws -> Bool
