import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "remove <object>" command (or "take off <object>").
struct TakeOffHandler {
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            return [.showText("What do you want to take off?")]
        }

        let objectID = Object.ID(objectIDString)
        guard let object = world.find(objectID) else {
            // Player isn't wearing something they can't see (or doesn't exist)
            return [.showText("You aren't wearing that.")]
        }

        // Get object component for flag checks
        guard var objectComponent = object.find(ObjectComponent.self) else {
            // Object exists but doesn't have basic properties? Cannot be worn/taken off.
            return [.showText("You can't take that off.")] // Or maybe "You aren't wearing that." is better?
        }

        // Check if the player is actually wearing it
        guard objectComponent.flags.contains(.worn) else {
            return [.showText("You aren't wearing that.")]
        }

        // Check if the object's location is the player (worn items are implicitly held)
        // This might be redundant if the .worn flag check is sufficient, but good for safety.
        guard object.find(LocationComponent.self)?.parentID == world.player.id else {
            // This case should ideally not happen if .worn is true, but handles edge cases.
            print("⚠️ Warning: Object \(objectID) marked as worn but not located on player.")
            return [.showText("You aren't wearing that.")]
        }

        // Take off the object (remove the .worn flag)
        world.modify(id: object.id) {
            $0.removeFlag(.worn)
        }

        world.mention(objectID)

        // Use the object's name from the DescriptionComponent if available
        let name = object.find(DescriptionComponent.self)?.name ?? objectIDString
        return [.showText("You take off the \(name).")]
    }
}

// Assuming Object extension for .theName exists and ObjectComponent access
// TODO: Consider adding Object helpers like hasFlag(_:), setFlag(_:), removeFlag(_:), needs DescriptionComponent
