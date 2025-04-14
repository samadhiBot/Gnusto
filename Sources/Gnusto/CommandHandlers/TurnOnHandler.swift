import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "turn on <object>" command.
struct TurnOnHandler {
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        // Get current location and check if it's dark *before* the action
        guard let playerLocation = world.playerLocation else {
            // Should not happen in normal gameplay
            return [.showText("You seem to be nowhere at all.")]
        }
        let wasDark = !world.isIlluminated(playerLocation.id)

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            return [.showText("What do you want to turn on?")]
        }

        let objectID = Object.ID(objectIDString)

        // Find the object: Check player inventory first, then the current location.
        // Do this *before* checking visibility, as turning on works in the dark.
        let object: Object?
        if let playerInventoryObject = world.find(in: world.player.id).first(where: { $0.id == objectID }) {
            object = playerInventoryObject
        } else if let roomLocation = world.playerLocation?.id, let roomObject = world.find(in: roomLocation).first(where: { $0.id == objectID }) {
            object = roomObject
        } else {
            object = nil // Object not found in inventory or room
        }

        guard var foundObject = object else {
            // If not found in inventory or location, *then* say you don't see it.
            return [.showText("You don't see '\(objectIDString)' here.")]
        }

        world.mention(foundObject.id) // Mention the found object ID

        // Check if it's a device
        guard foundObject.find(ObjectComponent.self)?.flags.contains(Flag.device) ?? false else {
            return [.showText("You can't turn \(foundObject.theName) on.")]
        }

        // Check specifically if it's a light source using modify
        var turnedOn = false
        var alreadyOn = false
        world.modify(id: foundObject.id) { object in
            object.modify(LightSourceComponent.self) { lightSource in
                if lightSource.isOn {
                    alreadyOn = true
                } else {
                    lightSource.isOn = true
                    turnedOn = true
                }
            }
            // Check state *after* object.modify call completes
            print("--- TurnOnHandler: Inside world.modify, object \(object.id) lightSource.isOn = \(object.find(LightSourceComponent.self)?.isOn ?? false) ---")
        }

        if alreadyOn {
            return [.showText("\(foundObject.theName.capped) is already on.")]
        }

        if turnedOn {
            var effects: [Effect] = [.showText("You turn on \(foundObject.theName).")]
            print("--- TurnOnHandler: wasDark = \(wasDark) ---") // Diagnostic print
            // If the room was dark and now presumably isn't, trigger a look.
            if wasDark {
                effects.append(.triggerImplicitLook)
            }
            return effects
        } else {
            // modify closure wasn't entered, meaning no LightSourceComponent found
            // If it's a device but not a known type like LightSource
            return [.showText("You try to turn on \(foundObject.theName), but nothing happens.")]
        }

        // TODO: Handle other types of devices if necessary
    }
}

// Assuming Object extension for .theName/.theName.capped exists
