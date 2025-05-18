import Foundation

/// Handles the "QUIT" (or "Q") command, allowing the player to end the game session.
struct QuitActionHandler: ActionHandler {

    // MARK: - ActionHandler Methods

    /// Validates the "QUIT" command.
    /// Currently, quit requires no specific validation and always proceeds.
    func validate(context: ActionContext) async throws {
        // No validation needed for QUIT.
    }

    /// Processes the "QUIT" command.
    ///
    /// This action requests the `GameEngine` to terminate the game and produces a
    /// "Goodbye!" message. Future enhancements might include a confirmation step.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the farewell message.
    func process(context: ActionContext) async throws -> ActionResult {
        await context.engine.requestQuit()

        return ActionResult("Goodbye!")
    }
}
