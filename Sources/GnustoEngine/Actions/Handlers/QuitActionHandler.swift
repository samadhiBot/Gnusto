import Foundation

/// Handles the "QUIT" (or "Q") command, allowing the player to end the game session.
public struct QuitActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.quit, "q"]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "QUIT" command.
    ///
    /// This action displays the player's current score and move count, then prompts
    /// for confirmation before quitting. If confirmed, it requests the GameEngine
    /// to terminate the game. If declined, the game continues.
    public func process(context: ActionContext) async throws -> ActionResult {
        let currentScore = await context.player.score
        let currentMoves = await context.player.moves
        let maxScore = context.engine.maximumScore

        // Print the prompt without a newline and get user input
        await context.engine.ioHandler.print(
            context.msg.quitScoreAndPrompt(
                currentScore,
                maxScore: maxScore,
                moves: currentMoves
            ),
            style: .normal,
            newline: false
        )

        guard let response = await context.engine.ioHandler.readLine(prompt: "") else {
            // Handle EOF/nil input as quit confirmation
            return ActionResult(
                context.msg.goodbye(),
                .requestGameQuit
            )
        }

        let trimmedResponse = response.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()

        if ["yes", "y"].contains(trimmedResponse) {
            // User confirmed quit
            return ActionResult(
                context.msg.goodbye(),
                .requestGameQuit
            )
        } else if ["no", "n"].contains(trimmedResponse) {
            // User cancelled quit
            return ActionResult(
                context.msg.quitCancelled()
            )
        } else {
            return ActionResult(
                context.msg.yesNoFumble()
            )
        }
    }
}
