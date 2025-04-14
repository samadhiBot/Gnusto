import Foundation

/// Handles the "eat <object>" command.
struct EatHandler {

    /// Processes the eat command.
    ///
    /// - Parameters:
    ///   - command: The user input command, specifying the direct object to eat.
    ///   - world: The game world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(command: UserInput, world: World) -> [Effect]? {
        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("What do you want to eat?")]
        }

        let targetID = Object.ID(targetIDString)
        guard let targetObject = world.find(targetID) else {
            // Handle ambiguous cases like "eat food" if multiple food items exist
            // This might require more sophisticated parsing or prompting.
            return [.showText("You don't see '\(targetIDString)' here.")]
        }

        // Check if accessible (in inventory or room)
        guard targetObject.isAccessible(to: world.player.id, in: world) else {
            return [.showText("You can't reach \(targetObject.theName) to eat it.")]
        }

        world.mention(targetID)

        // Check if it's actually edible
        guard targetObject.find(ObjectComponent.self)?.flags.contains(.edible) ?? false else {
            // Provide different messages for inedible things vs. things that just aren't food.
            // This might require more flags or components (e.g., .food vs .inedibleObject)
            return [.showText("You can't eat \(targetObject.theName).")]
        }

        // Check if it's held by the player (some games require this)
        // guard targetObject.find(LocationComponent.self)?.parentID == world.player.id else {
        //     return [.showText("You need to be holding \(targetObject.theName) to eat it.")]
        // }

        // --- Perform the eating action ---

        // Remove the object from the world
        world.remove(targetObject.id)

        // Maybe add a nutrition effect, score points, etc.
        // e.g., world.player.modify(StatsComponent.self) { $0.hunger -= 10 }

        return [.showText("You eat \(targetObject.theName).")]
    }
}

// Requires: World, Effect, Object, Object.ID, UserInput, ObjectComponent, Flag (.edible)
// Requires: Object extension for .theName, .isAccessible(to:in:)
// Requires: World extension for .remove(_:)
