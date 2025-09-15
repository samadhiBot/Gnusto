import Foundation

/// Handles the "RESTART" command for restarting the game from the beginning.
/// Follows ZIL traditions for game restart functionality.
public struct RestartActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.restart]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "RESTART" command.
    ///
    /// Confirms with the player that they want to restart, then initiates the restart.
    /// This will end the current game session and prompt for a new one.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Print the prompt without a newline and get user input
        await context.engine.ioHandler.print(
            context.msg.restartConfirmation(),
            style: .normal,
            newline: false
        )

        guard let response = await context.engine.ioHandler.readLine(prompt: "") else {
            // Handle EOF/nil input as restart confirmation
            await context.engine.requestRestart()
            return ActionResult.yield
        }

        let trimmedResponse = response.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()

        if ["yes", "y"].contains(trimmedResponse) {
            // User confirmed restart
            await context.engine.requestRestart()
            return ActionResult.yield
        } else if ["no", "n"].contains(trimmedResponse) {
            // User cancelled restart
            return ActionResult(
                context.msg.restartCancelled()
            )
        } else {
            return ActionResult(
                context.msg.yesNoFumble()
            )
        }
    }
}
