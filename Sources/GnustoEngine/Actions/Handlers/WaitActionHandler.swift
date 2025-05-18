import Foundation

/// Handles the "WAIT" command, allowing the player to pass a turn without performing
/// any specific action other than advancing game time.
struct WaitActionHandler: ActionHandler {
    /// Processes the "WAIT" command.
    ///
    /// This action always succeeds and results in a generic message indicating that time
    /// has passed. It does not directly cause any state changes or side effects beyond
    /// advancing the game turn, which is handled by the `GameEngine`.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message "Time passes."
    func process(context: ActionContext) async throws -> ActionResult {
        // Waiting is always successful and produces a standard message.
        // It doesn't change state or cause side effects directly.
        ActionResult("Time passes.")
    }

    // Default implementations for validate() and postProcess() are used.
    // The default postProcess will print the message from the ActionResult.
}
