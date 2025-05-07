import Foundation

/// Enhanced `ActionHandler` protocol with distinct validation, processing, and post-processing steps.
///
/// This protocol provides a more structured way to handle complex actions that involve
/// multiple stages or potential side effects.
/// Note: This protocol is Sendable as its methods now use Sendable types.
public protocol ActionHandler: Sendable {
    /// Validates if the action can be performed given the current game state.
    /// This step should check prerequisites but not modify the game state.
    /// - Parameters:
    ///   - context: The context surrounding the action execution.
    /// - Throws: An `ActionError` if validation fails.
    func validate(
        context: ActionContext
    ) async throws

    /// Processes the core logic of the action and determines the outcome.
    /// This step may modify the game state temporarily or calculate intended changes.
    /// - Parameters:
    ///   - context: The context surrounding the action execution.
    /// - Returns: An `ActionResult` detailing the outcome, including success status, messages, state changes, and side effects.
    /// - Throws: An `ActionError` or other error if processing fails unexpectedly.
    func process(
        context: ActionContext
    ) async throws -> ActionResult

    /// Handles any follow-up effects after the action has been processed.
    /// This step applies the state changes and triggers side effects defined in the `ActionResult`.
    /// It might also handle displaying messages to the player.
    /// - Parameters:
    ///   - context: The context surrounding the action execution.
    ///   - result: The `ActionResult` returned by the `process` step.
    /// - Throws: An error if post-processing fails.
    func postProcess(
        context: ActionContext,
        result: ActionResult
    ) async throws
}

// MARK: - Default Implementation

extension ActionHandler {
    public func validate(
        context: ActionContext
    ) async throws {
        // Default: No specific validation required.
    }

    /// Optional step for handlers needing custom logic after `process` returns, but before
    /// the engine applies state changes or prints the message.
    ///
    /// The default implementation does nothing.
    public func postProcess(
        context: ActionContext,
        result: ActionResult
    ) async throws {
        // Default: Do nothing
    }
}

// MARK: - Associated Types & Aliases

/// A closure that handles a specific action potentially targeting a specific item.
/// Return `true` if the action was fully handled (preventing default verb handler), `false` otherwise.
public typealias ObjectActionHandler = @Sendable (GameEngine, Command) async throws -> Bool
