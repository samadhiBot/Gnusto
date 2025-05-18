import Foundation

/// Handles the "SCORE" command, displaying the player's current score and turn count.
struct ScoreActionHandler: ActionHandler {
    /// Processes the "SCORE" command.
    ///
    /// This action retrieves the player's current score and number of moves from the
    /// `GameState` and formats them into a message for the player.
    /// It does not cause any state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the player's score and move count.
    func process(context: ActionContext) async throws -> ActionResult {
        // Fetch current score and turn count
        let currentScore = await context.engine.gameState.player.score
        let turnCount = await context.engine.gameState.player.moves

        // The SCORE context.command only reports information, it doesn't change state.
        return ActionResult("Your score is \(currentScore) in \(turnCount) moves.")
    }

    // Default implementations for validate() and postProcess() are used.
    // Default postProcess will print the message from ActionResult.
}
