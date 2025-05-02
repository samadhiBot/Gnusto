import Foundation

/// Action handler for the SCORE verb.
struct ScoreActionHandler: EnhancedActionHandler {

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Fetch current score and turn count
        let currentScore = await engine.playerScore
        let turnCount = await engine.playerMoves

        // The SCORE command only reports information, it doesn't change state.
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
