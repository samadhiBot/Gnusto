import Foundation

/// Handles the "QUIT" (or "Q") command, allowing the player to end the game session.
public struct QuitActionHandler: ActionHandler {
    public init() {}

    /// Processes the "QUIT" command.
    ///
    /// This action displays the player's current score and move count, then prompts
    /// for confirmation before quitting. If confirmed, it requests the GameEngine
    /// to terminate the game. If declined, the game continues.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the appropriate message.
    public func process(context: ActionContext) async throws -> ActionResult {
        let engine = context.engine
        let currentScore = await engine.playerScore
        let currentMoves = await engine.playerMoves
        let maxScore = engine.maximumScore

        // Display score and prompt for confirmation
        let promptMessage = context.message.quitScoreAndPrompt(
            score: currentScore,
            maxScore: maxScore,
            moves: currentMoves
        )

        // Print the prompt without a newline and get user input
        await engine.ioHandler.print(promptMessage, style: .normal, newline: false)

        // Loop until we get a valid Y/N response
        while true {
            guard let response = await engine.ioHandler.readLine(prompt: "") else {
                // Handle EOF/nil input as quit confirmation
                await engine.requestQuit()
                return ActionResult(context.message.goodbye())
            }

            let trimmedResponse = response.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).lowercased()

            if trimmedResponse == "y" || trimmedResponse == "yes" {
                // User confirmed quit
                await engine.requestQuit()
                return ActionResult(context.message.goodbye())
            } else if trimmedResponse == "n" || trimmedResponse == "no" {
                // User cancelled quit
                return ActionResult(context.message.quitCancelled())
            } else {
                // Invalid response, ask again
                await engine.ioHandler.print(
                    context.message.quitConfirmationHelp() + " ",
                    style: .normal,
                    newline: false
                )
            }
        }
    }
}
