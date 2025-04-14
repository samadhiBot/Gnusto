import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Flag are available.

/// Handles the "examine <object>" command (and potentially "look at <object>").
struct ExamineHandler {

    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        // Darkness Check:
        if let locationID = world.playerLocation?.id, !world.isIlluminated(locationID) {
            // Allow examining self or held items in the dark
            var targetIsHeld = false
            if let targetIDString = command.directObject,
               let targetObject = world.find(Object.ID(targetIDString)) // Find the object regardless of location first
            {
                if targetObject.find(LocationComponent.self)?.parentID == world.player.id {
                    targetIsHeld = true
                }
            }
            let targetIsSelf = command.directObject == world.player.name

            if !targetIsSelf && !targetIsHeld {
                 if command.directObject == nil {
                     // General examine in the dark with no target
                     return [.showText("It's too dark to see anything.")]
                 } else {
                     // Trying to examine something specific (not held) in the dark
                     return [.showText("It's too dark to see that!")] // More specific message
                 }
            }
            // If target is self or held, proceed with examination even in dark
        }

        guard let objectIDString = command.directObject,
              !objectIDString.isEmpty
        else {
            // Handle bare "examine" - maybe look around?
            // For now, require an object.
            return [.showText("What do you want to examine?")]
        }

        let objectID = Object.ID(objectIDString)

        // Find the object - needs scoping rules!
        // Should look in inventory first, then location.
        // Simple approach for now: find anywhere.
        guard let object = world.find(objectID) else {
            return [.showText("You don't see any '\(objectIDString)' here.")]
        }

        world.mention(objectID)

        // Get the basic description
        guard let descComponent = object.find(DescriptionComponent.self) else {
            return [.showText("You see nothing special about \(object.theName).")]
        }

        var effects: [Effect] = []
        effects.append(.showText(descComponent.description))

        // Check if it's a container and list contents if visible
        if let containerComponent = object.find(ContainerComponent.self) {
            let containerEffects = handleContainer(object, component: containerComponent, world: world)
            effects.append(contentsOf: containerEffects)
        }

        // Check if it's readable
        if object.find(ObjectComponent.self)?.flags.contains(Flag.readable) ?? false {
             // Perhaps add: "You could try reading it."
             // Or just rely on ReadHandler for the action
        }

        // TODO: Add other details based on components/flags (e.g., is it lit? worn?)

        // Highlight object? (Assuming .highlightObject is not a standard effect)
        // effects.append(.highlightObject(name: descComponent.name))

        return effects
    }

    /// Handles describing the contents of a container.
    private static func handleContainer(
        _ container: Object,
        component: ContainerComponent,
        world: World // Keep world here, not from context
    ) -> [Effect] {
        var effects: [Effect] = []

        // Determine visibility (open or transparent flag)
        let isTransparent = container.find(ObjectComponent.self)?.flags.contains(Flag.transparent) ?? false
        let isVisible = component.isOpen || isTransparent

        if isVisible {
            let contents = world.find(in: container.id)
            if !contents.isEmpty {
                let contentNames = contents
                    .compactMap { $0.find(DescriptionComponent.self)?.name }
                    .sorted()
                    .joined(separator: ", ")
                effects.append(.showText("\(container.theName.capped) contains: \(contentNames)."))
            } else {
                effects.append(.showText("\(container.theName.capped) is empty."))
            }
        } else {
            effects.append(.showText("\(container.theName.capped) is closed."))
        }

        return effects
    }
}

// Assuming Object extension for .theName/.theName.capped exists
// TODO: Define Flag.transparent
// TODO: Define Flag.readable
// TODO: Add Object flag helpers like hasFlag()
