import Foundation

/// Handles the "put <obj> on <surface>" command.
struct PutOnHandler {
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        // Identify the object to put and the surface
        guard let objectIDString = command.directObject,
              let surfaceIDString = command.indirectObject,
              // Ensure preposition was "on" or similar - assumed handled by registry
              !objectIDString.isEmpty, !surfaceIDString.isEmpty
        else {
            // Handle incomplete commands
            if command.directObject == nil && command.indirectObject != nil {
                return [.showText("What do you want to put on the \(command.indirectObject!)?")]
            } else if command.directObject != nil && command.indirectObject == nil {
                 return [.showText("Where do you want to put the \(command.directObject!)?")] // Or maybe "Put it on what?"
            } else {
                 return [.showText("What do you want to put on what?")]
            }
        }

        let objectID = Object.ID(objectIDString)
        let surfaceID = Object.ID(surfaceIDString)

        // --- Basic Checks ---
        guard let object = world.find(objectID) else {
            return [.showText("You don't see any '\(objectIDString)' here.")]
        }
        guard let surface = world.find(surfaceID) else {
            return [.showText("You don't see any '\(surfaceIDString)' here.")]
        }

        // Prevent putting an object on itself
        if objectID == surfaceID {
            // Consider if this should be allowed for some items?
            return [.showText("You can't put something on itself.")]
        }

        // Check if the player is holding the object
        guard object.find(LocationComponent.self)?.parentID == world.player.id else {
            return [.showText("You aren't holding \(object.theName).")] // Use specific name here
        }

        // --- Surface Check ---
        // Check if the target is actually a surface
        // Assumption: Surfaces have an ObjectComponent with a .surface flag
        guard let surfaceObjectComponent = surface.find(ObjectComponent.self),
              surfaceObjectComponent.flags.contains(.surface) // Assumes Flag.surface exists
        else {
            return [.showText("You can't put things on \(surface.theName).")]
        }

        // --- Container/Surface Interaction (Optional Refinement) ---
        // Optional: Check if the surface is *also* a container and if it's open?
        // If putting something *on* a closed container lid is desired, this needs thought.
        // For now, we allow putting things on surfaces regardless of open/closed state if they are also containers.

        // --- Capacity Check (Optional) ---
        // TODO: Add capacity check logic if surfaces have limits

        // --- Perform the move ---
        world.move(objectID, to: surfaceID)
        world.mention(objectID) // Mention the object being moved

        // Return success message
        return [.showText("You put the \(object.theName) on the \(surface.theName).")]
    }
}

// Requires: World, Effect, Object, Object.ID, UserInput, CommandContext
// Requires: LocationComponent, ObjectComponent, Flag.surface (Assumed)
// Requires: Object extensions .theName, .name
