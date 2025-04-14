import Foundation

// Note: Assumes World, Effect, UserInput are available.

/// Handles the "quit" command.
struct QuitHandler {

    /// Ends the game.
    static func handle(context: CommandContext) -> [Effect]? {
        let world = context.world
        // let command = context.userInput // Command details likely not needed

        // Check for extra words (e.g., "quit game") - generally ignore them
        // We could return nil if command.directObject != nil etc., but usually
        // "quit" is intended regardless of extra words.

        world.updateState(to: .quit)
        // Return effects including the endgame signal
        return [
            .showText("Thanks for playing!"),
            .endGame
        ]
    }
}
