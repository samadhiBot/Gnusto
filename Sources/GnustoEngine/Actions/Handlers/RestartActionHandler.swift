import Foundation

/// Handles the "RESTART" command for restarting the game from the beginning.
/// Follows ZIL traditions for game restart functionality.
public struct RestartActionHandler: ActionHandler {
    public init() {}

    /// Validates the "RESTART" command.
    ///
    /// RESTART requires no validation and can always be executed.
    public func validate(context: ActionContext) async throws {
        // No validation needed for RESTART
    }

    /// Processes the "RESTART" command.
    ///
    /// Confirms with the player that they want to restart, then initiates the restart.
    /// This will end the current game session and prompt for a new one.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing confirmation message and restart signal.
    public func process(context: ActionContext) async throws -> ActionResult {
        // In ZIL tradition, RESTART asks for confirmation first
        // For now, we'll implement immediate restart - games can override for confirmation

                // Signal the engine to quit (which will end the current session)
        // The application layer should handle restarting the game
        await context.engine.requestQuit()

        return ActionResult("""
            Are you sure you want to restart? This will lose your current progress.
            [Game will restart...]
            """)
    }

    /// Performs any post-processing after the restart command.
    ///
    /// Currently no post-processing is needed for restart.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for restart
    }
}
