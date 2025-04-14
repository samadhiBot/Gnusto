import Foundation

/// Handles the "open <object>" command.
struct OpenHandler {

    /// Processes the open command.
    ///
    /// - Parameters:
    ///   - context: The command context containing user input and world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("What do you want to open?")]
        }

        let targetID = Object.ID(targetIDString)
        guard let targetObject = world.find(targetID) else {
            return [.showText("You don't see '\(targetIDString)' here.")]
        }

        world.mention(targetID)

        // Check if it's locked first
        if let objectComponent = targetObject.find(ObjectComponent.self),
           objectComponent.flags.contains(.locked)
        {
            return [.showText("\(targetObject.theName.capped) is locked.")]
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

        // Default: Cannot be opened
        return [.showText("You can't open \(targetObject.theName).")]
    }

    /// Handles opening a container.
    private static func handleContainer(_ container: Object, world: World) -> [Effect]? {
        // Get the current component using find()
        guard var containerComponent = container.find(ContainerComponent.self) else {
             return [.showText("You can't open \(container.theName).")]
        }

        if containerComponent.isOpen {
            return [.showText("\(container.theName.capped) is already open.")]
        }

        // Modify the component struct copy
        containerComponent.isOpen = true

        // Write the modified component back to the object instance
        world.modify(id: container.id) { object in
            object.add(containerComponent)
        }

        var effects: [Effect] = [.showText("You open \(container.theName).")]

        // If the container is not opaque, describe contents
        // We need the ObjectComponent to check the opaque flag
        let isOpaque = container.find(ObjectComponent.self)?.flags.contains(.opaque) ?? false
        if !isOpaque {
            let contents = world.contents(of: container.id)
            if contents.isEmpty {
                effects.append(.showText("It's empty."))
            } else {
                let contentNames = contents.map { $0.aName }.joined(separator: ", ")
                effects.append(.showText("Inside, you see: \(contentNames)."))
            }
        }

        return effects
    }

    /*
    /// Handles opening a door.
    /// Assumes a DoorComponent exists with properties like isOpen and potentially linkedRoom.
    private static func handleDoor(_ object: Object, world: World) -> [Effect]? {
        guard let door = object.find(DoorComponent.self) else {
             return [.showText("Error: Expected a door but found none.")]
        }

        if door.isOpen {
            return [.showText("\(object.theName.capped) is already open.")]
        }

        // Modify the component to set isOpen to true
        object.modify(DoorComponent.self) { component in
            component.isOpen = true
        }

        // Potentially reveal the linked room or update its description
        // This depends heavily on how doors and rooms are implemented.

        return [.showText("You open \(object.theName).")]
    }
    */
}

// Requires: World, Effect, Object, Object.ID, UserInput, ContainerComponent, ObjectComponent, Flag (.locked, .opaque)
// Potentially: DoorComponent
// Requires: Object extension for .theName/.theName.capped, .aName
// Requires: World.contents(of:)
