import Foundation

// Note: Assumes World, Effect, UserInput are available.

/// Handles the "save" command.
struct SaveHandler {

    /// Placeholder for saving the game state.
    static func handle(context: CommandContext) -> [Effect]? {
        // TODO: Implement actual game saving mechanism.
        // This would likely involve serializing the `world` state.
        // Consider where the save file is stored and how it's named.

        // Ignore extra input for now (e.g., "save mygame")

        return [.showText("Game saved. (Not implemented yet)")]
    }
}
