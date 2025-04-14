import Foundation

// Note: Assumes Effect, UserInput, World are available.

/// Handles the "help" command.
struct HelpHandler {

    static func handle(context: CommandContext) -> [Effect]? {
        // Ignore any parameters for now (e.g., "help take")
        // let command = context.userInput
        // let world = context.world

        // Return the static help text
        return [.showText("""
            Available commands:
            - Movement: go, walk, climb, jump, swim
            - Object manipulation: take, drop, put in, put on, remove, wear
            - Examination: look, examine, look under, search
            - Object state: open, close, lock, unlock, turn on, turn off
            - Character actions: eat, drink, read, talk, wave
            - Combat: attack
            - Meta: help, inventory, quit, save, restore, undo, version
            """)]
    }
}
