import Foundation

/// Handles the "SCORE" command, displaying the player's current score and turn count.
public struct ScoreActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.score]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SCORE" command.
    ///
    /// This action retrieves the player's current score and number of moves from the
    /// `GameState` and formats them into a message for the player.
    /// It does not cause any state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        await ActionResult(
            context.msg.currentScore(
                context.player.score,
                maxScore: context.engine.maximumScore,
                moves: context.player.moves
            )
        )
    }
}
