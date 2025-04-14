import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "drop <object>" command.
struct DropHandler {

    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            return [.showText("What do you want to drop?")]
        }

        let objectID = Object.ID(objectIDString)
        guard let object = world.find(objectID) else {
            return [.showText("You don't have '\(objectIDString)'.")] // Assume if not found, player doesn't have it
        }

        // Check if the player is actually holding the object
        let locationComponent = object.find(LocationComponent.self)
        guard locationComponent?.parentID == world.player.id else {
            // Might be visible but not held
            return [.showText("You aren't holding \(object.theName).")]
        }

        // Check if the object is currently worn
        if object.find(ObjectComponent.self)?.flags.contains(Flag.worn) ?? false {
            return [.showText("You are wearing \(object.theName). You'll need to remove it first.")]
        }

        // Get player location to drop the object into
        guard let playerLocationID = world.playerLocation?.id else {
            return [.showText("There's nowhere to drop \(object.theName) here.")]
        }

        // Drop the object into the current location
        world.move(objectID, to: playerLocationID)
        world.mention(objectID)

        // Return the effects
        // Note: .showInventoryChange is not a standard Effect, assuming custom effect or just text.
        return [
            .showText("Dropped.") // Simple confirmation
            // Or: .showText("You drop \(object.theName).")
        ]
    }
}

// Assuming Object extension for .theName exists from PutInHandler
