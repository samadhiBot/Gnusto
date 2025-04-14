import Foundation

/// Handles the "wave" command.
struct WaveHandler {

    /// Processes the wave command.
    ///
    /// Currently, this is a placeholder and just acknowledges the action.
    /// Future enhancements could include checking if the object can be waved,
    /// targetting specific objects or characters, etc.
    ///
    /// - Parameters:
    ///   - command: The user input, potentially containing the direct object to wave.
    ///   - world: The game world state.
    /// - Returns: An array of effects, usually `showText`.
    static func handle(command: UserInput, world: World) -> [Effect]? {
        guard let target = command.directObject, !target.isEmpty else {
            return [.showText("What would you like to wave?")]
        }
        world.mention(Object.ID(target)) // Mention the object being waved
        // TODO: Implement a more sophisticated waving system.
        //       - Check if the player is holding the object.
        //       - Check if the object is suitable for waving (e.g., not too heavy, fixed).
        //       - Check if there's an indirect object (e.g., "wave handkerchief at guard").
        return [.showText("You wave the \(target).")]
    }
}
