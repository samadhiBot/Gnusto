import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "take <object>" command.
struct TakeHandler {

    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            return [.showText("What do you want to take?")]
        }

        let objectID = Object.ID(objectIDString)

        // Find the object in the player's current location
        guard let playerLocationID = world.playerLocation?.id else {
             return [.showText("You aren't anywhere you can take things from.")]
        }

        // Search for the object specifically within the player's location
        // TODO: This needs a more robust object resolution system (scope, disambiguation)
        let objectsInLocation = world.find(in: playerLocationID)
        guard let object = objectsInLocation.first(where: { $0.id == objectID }) else {
             // Or check if it exists elsewhere? For now, assume it needs to be here.
             return [.showText("You don't see any '\(objectIDString)' here.")]
        }

        // Check if the object is takeable
        guard object.find(ObjectComponent.self)?.flags.contains(Flag.takeable) ?? false else {
            return [.showText("You can't take \(object.theName).")]
        }

        // Check if the player already has it
        let locationComponent = object.find(LocationComponent.self)
        if locationComponent?.parentID == world.player.id {
            return [.showText("You already have \(object.theName).")]
        }

        // TODO: Add checks for container state (is it inside something closed?)
        // TODO: Add checks for weight/capacity limits

        // Take the object (move to player)
        world.move(objectID, to: world.player.id)
        world.mention(objectID)

        // Return the effect
        // Note: .showInventoryChange is not standard
        return [
            .showText("You take \(object.theName).")
        ]
    }
}

// Assuming Object extension for .theName exists
