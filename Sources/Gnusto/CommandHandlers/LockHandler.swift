import Foundation

/// Handles the "lock <object> with <key>" command.
struct LockHandler {

    /// Processes the lock command.
    ///
    /// - Parameters:
    ///   - context: The command context containing user input and world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("What do you want to lock?")]
        }
        guard let keyIDString = command.indirectObject, !keyIDString.isEmpty else {
            // Check if preposition was used without a key
            if command.hasPreposition {
                return [.showText("Lock \(targetIDString) with what?")]
            } else {
                // TODO: Could try to find a key in inventory?
                return [.showText("You need to specify what to lock it with.")]
            }
        }

        let targetID = Object.ID(targetIDString)
        let keyID = Object.ID(keyIDString)

        guard let targetObject = world.find(targetID) else {
            return [.showText("You don't see '\(targetIDString)' here.")]
        }
        guard let keyObject = world.find(keyID) else {
             return [.showText("You don't have '\(keyIDString)'.")]
        }

        // Ensure the key is held by the player
        guard keyObject.find(LocationComponent.self)?.parentID == world.player.id else {
            return [.showText("You aren't holding \(keyObject.theName).")]
        }

        world.mention(targetID)

        // Check if the target has the necessary components and flags
        guard
            let objectComponent = targetObject.find(ObjectComponent.self),
            objectComponent.flags.contains(.lockable)
        else {
            return [.showText("You can't lock \(targetObject.theName).")]
        }

        guard !objectComponent.flags.contains(.locked) else {
            return [.showText("\(targetObject.theName.capped) is already locked.")]
        }

        // Check for container and matching key
        guard
            let containerComponent = targetObject.find(ContainerComponent.self),
            containerComponent.keyID == keyID
        else {
            // Provide more specific feedback if possible
            if targetObject.find(ContainerComponent.self)?.keyID != keyID {
                return [.showText("\(keyObject.theName.capped) doesn't seem to fit the lock.")]
            } else {
                return [.showText("You can't lock \(targetObject.theName).")]
            }
        }

        // --- Lock the object ---
        world.modify(id: targetObject.id) { object in
            object.modify(ObjectComponent.self) { component in
                component.flags.insert(.locked) // Add the .locked flag
            }
        }

        // If it's an open container, close it first
        if let container = targetObject.find(ContainerComponent.self), container.isOpen {
            world.modify(id: targetObject.id) { object in
                object.modify(ContainerComponent.self) {
                    $0.isOpen = false
                }
            }
            return [.showText("You close and lock \(targetObject.theName).")]
        } else {
            return [.showText("You lock \(targetObject.theName).")]
        }
    }
}

// Requires: World, Effect, Object, Object.ID, UserInput, LocationComponent, ObjectComponent, ContainerComponent, Flag (.lockable, .locked)
// Requires: Object extension for .theName/.theName.capped
