import Foundation

/// Handles the "RESTART" command for restarting the game from the beginning.
/// Follows ZIL traditions for game restart functionality.
public struct RestartActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [Verb] = [.restart]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "RESTART" command.
    ///
    /// Confirms with the player that they want to restart, then initiates the restart.
    /// This will end the current game session and prompt for a new one.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Display confirmation prompt
        let promptMessage = "🤡 restart prompt message"
        // engine.messenger.restartConfirmation()

        // Print the prompt without a newline and get user input
        await engine.ioHandler.print(promptMessage, style: .normal, newline: false)

        return ActionResult("🤡 placeholder response")

        // Loop until we get a valid Y/N response
//        while true {
//            guard let response = await engine.ioHandler.readLine(prompt: "") else {
//                // Handle EOF/nil input as restart confirmation
//                await engine.requestRestart()
//                return ActionResult(
//                    engine.messenger.gameRestarting()
//                )
//            }
//
//            let trimmedResponse = response.trimmingCharacters(
//                in: .whitespacesAndNewlines
//            ).lowercased()
//
//            if trimmedResponse == "y" || trimmedResponse == "yes" {
//                // User confirmed restart
//                await engine.requestRestart()
//                return ActionResult(
//                    engine.messenger.gameRestarting()
//                )
//            } else if trimmedResponse == "n" || trimmedResponse == "no" {
//                // User cancelled restart
//                return ActionResult(
//                    engine.messenger.restartCancelled()
//                )
//            } else {
//                // Invalid response, ask again
//                await engine.ioHandler.print(
//                    engine.messenger.restartConfirmationHelp() + " ",
//                    style: .normal,
//                    newline: false
//                )
//            }
//        }
    }
}
