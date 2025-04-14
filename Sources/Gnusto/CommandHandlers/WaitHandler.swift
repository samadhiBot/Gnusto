import Foundation

// Note: Assumes World, Effect, UserInput are available.

/// Handles the "wait" command.
struct WaitHandler {

    /// Processes the wait command.
    ///
    /// - Parameter context: The command context.
    /// - Returns: An array of effects indicating time has passed.
    static func handle(context: CommandContext) -> [Effect]? {
        // let command = context.userInput // Not currently used
        // let world = context.world     // Not currently used

        // TODO: Integrate properly with turn-based event processing.
        // Ideally, this might trigger an Action like .wait(turns: 1) instead of
        // directly returning effects, but CommandHandler signature is [Effect]?
        // For now, just provide the basic feedback.

        // Ignore extra input like "wait for troll"

        return [.showText("Time passes...")]
    }
}
