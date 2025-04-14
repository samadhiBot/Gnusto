import Foundation

// Note: Assumes World, Effect, Object, Component types, UserInput, Direction are available.

/// Handles the "go" command and its variations (like single-word directions).
struct GoHandler {

    /// The main handler function for movement verbs ("go", "north", "south", etc.).
    /// This handler is invoked by the CommandRegistry after resolving the input verb
    /// (e.g., "walk", "n") to the canonical "go" VerbID.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        var targetDirection: Direction? = nil

        // Determine the target direction from the UserInput details.
        // Since the registry routed here, we know the *intent* is movement.

        // 1. Check if the verb itself is a direction (e.g., user typed "north").
        if let verb = command.verb,
           let direction = Direction(verb.rawValue),
           command.isSingleWord // Ensure it was *only* the direction word
        {
            targetDirection = direction
        }
        // 2. Check if the direct object is a direction (e.g., user typed "go north").
        else if let directionString = command.directObject,
                let direction = Direction(directionString)
        {
             // We could optionally check command.verb here if we wanted to ensure
             // the verb was explicitly "go", "walk", etc., but the registry mapping
             // mostly handles this. Check for extra words that might confuse.
             if !command.hasPreposition && !command.hasIndirectObject {
                 targetDirection = direction
             }
        }

        // If no valid direction pattern was found in the UserInput structure
        guard let direction = targetDirection else {
            // The structure was something this handler doesn't understand
            // (e.g., just "go", or "run wall", or maybe a complex sentence
            // that Nitfol parsed unexpectedly but mapped to the "go" verb ID).
            // Returning nil is often best, letting the dispatcher handle unknown structure.
            // However, specifically for the verb "go", a missing direction is common.
            // Use the canonical verb ID from context
            if context.canonicalVerbID == .go && !command.hasDirectObject && !command.hasPreposition {
                 return [.showText("Where do you want to go?")]
            }
            // For other cases (like "walk wall", or "north wall"), returning nil
            // lets the dispatcher say "I don't know how to 'walk' / 'north'..."
            return nil
        }

        // --- Found a valid direction, attempt move ---
        guard let currentLocation = world.playerLocation,
              let currentRoomComponent = currentLocation.find(RoomComponent.self)
        else {
            return [.showText("You seem unable to move from here.")]
        }

        // Check if the exit exists
        guard let exit = currentRoomComponent.exits[direction] else {
            // No exit defined in that direction
            return [.showText("You can't go that way.")]
        }

        // --- Check Destination Darkness and Visited Status ---
        // Get the potential destination ID from the Exit
        let potentialDestinationID: Object.ID
        switch exit {
        case .direct(let destID):
            potentialDestinationID = destID
        case .conditional(let conditional):
            potentialDestinationID = conditional.destination // Use the struct's property
        }

        // Check if the potential destination is an unknown dark room
        if let destinationRoom = world.find(potentialDestinationID),
           let destRoomComponent = destinationRoom.find(RoomComponent.self),
           !destRoomComponent.isLit, // Destination is inherently dark
           !world.visitedRooms.contains(potentialDestinationID) // And has not been visited
        {
                // Block entering *unknown* dark rooms
                return [.showText("You can't find your way there in the dark.")]
        }
        // --- End Darkness Check ---


        // Check if the exit is *actually* available (handles conditional logic)
        if let destinationId = exit.destination(in: world) {
            // Exit is available, move the player
            let onEnterEffects = world.movePlayer(to: destinationId)

            // Trigger a look after successful movement, applying onEnter effects first
            // Need to create a CommandContext for the look
            let lookActionInput = UserInput(verb: .look, rawInput: "look") // Use canonical .look
            let lookContext = CommandContext(
                userInput: lookActionInput,
                world: world, // Use the *current* world state after movePlayer
                canonicalVerbID: .look
            )
            var lookEffects = LookHandler.handle(context: lookContext) ?? []
            lookEffects.insert(contentsOf: onEnterEffects, at: 0)
            return lookEffects

        } else {
            // Exit is blocked
            let blockedMessage = exit.blockedMessage(in: world) ?? "You can't go that way."
            return [.showText(blockedMessage)]
        }
    }
}
