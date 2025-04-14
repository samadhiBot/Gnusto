import Foundation

/// Handles the "close <object>" command.
struct CloseHandler {

    /// Processes the close command.
    ///
    /// - Parameters:
    ///   - context: The command context containing user input and world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("What do you want to close?")]
        }

        let targetID = Object.ID(targetIDString)
        guard let targetObject = world.find(targetID) else {
            return [.showText("You don't see '\(targetIDString)' here.")]
        }

        world.mention(targetID)

        // Check if it has the openable flag - assumes components handle specific types
        guard targetObject.find(ObjectComponent.self)?.flags.contains(.openable) ?? false else {
            return [.showText("You can't close \(targetObject.theName).")]
        }

        // Handle Containers
        if targetObject.has(ContainerComponent.self) {
            return handleContainer(targetObject, world: world)
        }

        // Handle Doors (if DoorComponent exists)
        /*
        if targetObject.has(DoorComponent.self) {
            return handleDoor(targetObject, world: world)
        }
        */

        // Default: Cannot be closed (should be caught by .openable check, but for safety)
        return [.showText("You can't close \(targetObject.theName).")]
    }

    /// Handles closing a container.
    private static func handleContainer(_ object: Object, world: World) -> [Effect]? {
        guard let container = object.find(ContainerComponent.self) else {
            return [.showText("Error: Expected a container but found none.")]
        }

        if !container.isOpen {
            return [.showText("\(object.theName.capped) is already closed.")]
        }

        // Modify the component to set isOpen to false
        world.modify(id: object.id) { object in
            object.modify(ContainerComponent.self) { component in
                component.isOpen = false
            }
        }

        return [.showText("You close \(object.theName).")]
    }

    /*
    /// Handles closing a door.
    private static func handleDoor(_ object: Object, world: World) -> [Effect]? {
        guard let door = object.find(DoorComponent.self) else {
             return [.showText("Error: Expected a door but found none.")]
        }

        if !door.isOpen {
            return [.showText("\(object.theName.capped) is already closed.")]
        }

        object.modify(DoorComponent.self) { $0.isOpen = false }
        return [.showText("You close \(object.theName).")]
    }
    */
}

// Requires: World, Effect, Object, Object.ID, UserInput, ContainerComponent, ObjectComponent, Flag (.openable)
// Potentially: DoorComponent
// Requires: Object extension for .theName/.theName.capped
