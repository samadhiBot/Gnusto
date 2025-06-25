import Foundation

/// Handles the "SCORE" command, displaying the player's current score and turn count.
public struct ScoreActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.score]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods
    public init() {}
    /// Processes the "SCORE" command.
    ///
    /// This action retrieves the player's current score and number of moves from the
    /// `GameState` and formats them into a message for the player.
    /// It does not cause any state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the player's score and move count.
        // Fetch current score and turn count
        let currentScore = await engine.playerScore
        let turnCount = await engine.playerMoves

        return ActionResult(
            engine.messenger.currentScore(score: currentScore, moves: turnCount)
        )
    }

    // Default implementations for validate() and postProcess() are used.
    // Default postProcess will print the message from ActionResult.
}
