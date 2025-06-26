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
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Fetch current score and turn count
        let currentScore = await engine.playerScore
        let turnCount = await engine.playerMoves

        return ActionResult(
            engine.messenger.currentScore(score: currentScore, moves: turnCount)
        )
    }
}
