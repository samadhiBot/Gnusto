import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "wear <object>" command.
struct WearHandler {
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            return [.showText("What do you want to wear?")]
        }

        let objectID = Object.ID(objectIDString)
        guard let object = world.find(objectID) else {
            return [.showText("You don't have '\(objectIDString)'.")]
        }

        // Get object component for flag checks
        guard var objectComponent = object.find(ObjectComponent.self) else {
            // Object exists but doesn't have basic object properties?
            // This implies it cannot be worn.
            return [.showText("You can't wear \(object.theName).")]
        }

        // Check if player is already wearing it
        if objectComponent.flags.contains(.worn) {
            return [.showText("You're already wearing that.")]
        }

        // Check if the object is wearable
        guard objectComponent.flags.contains(.wearable) else {
            return [.showText("You can't wear that.")]
        }

        // Check if the player is holding the item
        guard object.find(LocationComponent.self)?.parentID == world.player.id else {
            return [.showText("You aren't holding that.")]
        }

        // Wear the object (add the .worn flag)
        world.modify(id: object.id) {
            $0.setFlag(.worn)
        }

        world.mention(objectID)

        return [.showText("You put on \(object.theName).")]
    }
}

// TODO: Consider adding Object helpers like hasFlag(_:), setFlag(_:), removeFlag(_:)
// Assuming Object extension for .theName exists
