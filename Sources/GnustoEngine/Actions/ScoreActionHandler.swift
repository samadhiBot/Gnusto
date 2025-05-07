import Foundation

/// Action handler for the SCORE verb.
struct ScoreActionHandler: ActionHandler {

    func process(context: ActionContext) async throws -> ActionResult {
        // Fetch current score and turn count
        let currentScore = await context.engine.gameState.player.score
        let turnCount = await context.engine.gameState.player.moves

        // The SCORE context.command only reports information, it doesn't change state.
        let message = "Your score is \(currentScore) in \(turnCount) moves."

        return ActionResult(
            success: true,
            message: message,
            stateChanges: [], // No state changes
            sideEffects: []  // No side effects
        )
    }

    // Relies on default validate() and postProcess().
    // Default postProcess will print the message from ActionResult.
}
