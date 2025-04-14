import Foundation

/// Handles the "put <obj> in <container>" command.
struct PutInHandler {
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        // Identify the object to put and the container
        guard let objectIDString = command.directObject,
              let containerIDString = command.indirectObject,
              // Ensure the preposition was something like "in" or "into" if needed?
              // For now, assume registry mapped "put" correctly.
              !objectIDString.isEmpty, !containerIDString.isEmpty
        else {
            // Handle cases like "put book", "put in chest"
            if command.directObject == nil && command.indirectObject != nil {
                return [.showText("What do you want to put in the \(command.indirectObject!)?")]
            } else if command.directObject != nil && command.indirectObject == nil {
                 return [.showText("Where do you want to put the \(command.directObject!)?")]
            } else {
                 return [.showText("What do you want to put where?")]
            }
        }

        let objectID = Object.ID(objectIDString)
        let containerID = Object.ID(containerIDString)

        guard let object = world.find(objectID),
              let container = world.find(containerID)
        else {
            // Try to be more specific about what wasn't found
            if world.find(objectID) == nil {
                 return [.showText("You don't see any '\(objectIDString)' here.")]
            } else {
                 return [.showText("You don't see any '\(containerIDString)' here.")]
            }
        }

        // Prevent putting an object inside itself
        if objectID == containerID {
            return [.showText("You can't put something in itself.")]
        }

        let containerName = container.name
        let objectName = object.name

        // Check if the target is actually a container
        guard let containerComponent = container.find(ContainerComponent.self),
              container.find(ObjectComponent.self)?.flags.contains(Flag.container) ?? false
        else {
            return [.showText("You can't put things in \(containerName).")]
        }

        // Check if the player is holding the object being put
        guard object.find(LocationComponent.self)?.parentID == world.player.id else {
            return [.showText("You aren't holding that.")]
        }

        // Check if the target container (and its parents up to the room) are open
        var currentContainerToCheck = container
        while true {
             // Is the current container open?
             if let currentContainerComp = currentContainerToCheck.find(ContainerComponent.self),
                !currentContainerComp.isOpen
             {
                 return [.showText("\(currentContainerToCheck.theName.capped) is closed.")]
             }

             // Get the parent
             guard let parentID = currentContainerToCheck.find(LocationComponent.self)?.parentID,
                   let parent = world.find(parentID) else {
                 // No parent or parent not found - stop checking up the chain
                 break
             }

             // Stop if we reach the player's immediate location (the room)
             if parentID == world.playerLocation?.id { break }

             // If parent is not a container, stop (shouldn't happen if structure is valid)
             guard parent.has(ContainerComponent.self) else { break }

             // Move up the chain
             currentContainerToCheck = parent
        }

        // Check capacity if implemented
        // TODO: Add capacity check logic here

        // Move the object into the container
        world.move(objectID, to: containerID)
        world.mention(objectID)

        // Return success message
        return [.showText("You put \(object.theName) in \(container.theName).")]
    }
}
