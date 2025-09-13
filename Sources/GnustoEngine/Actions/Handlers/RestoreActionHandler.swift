import Foundation

/// Handles the "RESTORE" command for restoring saved game state.
/// Provides game restore functionality following ZIL traditions.
public struct RestoreActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.restore, .load]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods
    public init() {}

    /// Processes the "RESTORE" command.
    ///
    /// Attempts to restore a previously saved game state. The actual restore mechanism
    /// is handled by the GameEngine's restore functionality.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Print the prompt without a newline and get user input
        await context.engine.ioHandler.print(
            context.msg.restoreConfirmation(),
            style: .normal,
            newline: false
        )

        guard let response = await context.engine.ioHandler.readLine(prompt: "") else {
            // Handle EOF/nil input as restore cancellation
            return ActionResult(
                context.msg.restoreCancelled()
            )
        }

        let trimmedResponse = response.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()

        if ["yes", "y"].contains(trimmedResponse) {
            do {
                // Request the engine to restore the game
                try await context.engine.restoreGame()
                return ActionResult(
                    context.msg.gameRestored()
                )
            } catch {
                // If restore fails, provide appropriate error message
                return ActionResult(
                    context.msg.restoreFailed(error.localizedDescription)
                )
            }
        } else if ["no", "n"].contains(trimmedResponse) {
            // User cancelled restore
            return ActionResult(
                context.msg.restoreCancelled()
            )
        } else {
            return ActionResult(
                context.msg.yesNoFumble()
            )
        }
    }
}
