import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "turn off <object>" command.
struct TurnOffHandler {
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            return [.showText("What do you want to turn off?")]
        }

        let objectID = Object.ID(objectIDString)
        guard let object = world.find(objectID) else {
            return [.showText("You don't see '\(objectIDString)' here.")]
        }

        world.mention(objectID)

        // Check if it's a device
        guard object.find(ObjectComponent.self)?.flags.contains(Flag.device) ?? false else {
            return [.showText("You can't turn \(object.theName) off.")]
        }

        // Check specifically if it's a light source
        if var lightSource = object.find(LightSourceComponent.self) {
            if !lightSource.isOn {
                return [.showText("\(object.theName.capped) is already off.")]
            }

            // Turn it off
            lightSource.isOn = false
            world.modify(id: object.id) { object in
                object.add(lightSource)
            }

            return [.showText("You turn off \(object.theName).")]
        }

        // TODO: Handle other types of devices if necessary

        // If it's a device but not a known type like LightSource
        return [.showText("You try to turn off \(object.theName), but nothing happens.")]
    }
}

// Assuming Object extension for .theName/.theName.capped exists
