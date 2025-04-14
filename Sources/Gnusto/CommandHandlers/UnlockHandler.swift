import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "unlock <object> with <key>" command.
struct UnlockHandler {
    /// Processes the unlock command.
    ///
    /// - Parameters:
    ///   - context: The command context containing user input and world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("What do you want to unlock?")]
        }
        guard let keyIDString = command.indirectObject, !keyIDString.isEmpty else {
            // Check if preposition was used without a key
            if command.hasPreposition {
                return [.showText("Unlock \(targetIDString) with what?")]
            } else {
                // Assume player might try "unlock <lock>" without specifying key
                // TODO: Could try to find a key in inventory?
                return [.showText("You need to specify what to unlock it with.")]
            }
        }

        // Validate prepositions if desired (e.g., must be "with")
        // if !command.prepositions.contains("with") { return nil } // Or specific message

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

        world.mention(targetID) // Mention after confirming key is held

        // Check if the target has the necessary components and flags
        guard
            let objectComponent = targetObject.find(ObjectComponent.self),
            objectComponent.flags.contains(.lockable) // Use dot syntax for enum cases
        else {
            return [.showText("You can't unlock \(targetObject.theName).")]
        }

        guard objectComponent.flags.contains(.locked) else { // Use dot syntax
            return [.showText("\(targetObject.theName.capped) is already unlocked.")]
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
                 // This case should technically be covered by the .lockable check,
                 // but adding for robustness in case flags/components get desynced.
                return [.showText("You can't unlock \(targetObject.theName).")]
            }
        }

        // --- Unlock the object ---
        // We know the ObjectComponent exists from the guards above.
        world.modify(id: targetObject.id) { object in
            object.modify(ObjectComponent.self) { component in
                component.flags.remove(.locked) // Use dot syntax
            }
        }

        return [.showText("You unlock \(targetObject.theName).")]
    }
}

// Assuming Object extension for .theName/.theName.capped exists
// Ensure Flag enum cases .lockable and .locked exist
// Ensure ContainerComponent has a keyID property of type Object.ID? or similar
