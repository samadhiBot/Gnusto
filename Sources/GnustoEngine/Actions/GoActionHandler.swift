import Foundation

/// Handles movement commands (e.g., "GO NORTH", "NORTH", "N").
public struct GoActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Identify Direction (Assume parser sets command.direction)
        guard let direction = command.direction else {
            // This should be caught by parser ensuring direction commands are valid
            throw ActionError.internalEngineError("Go command processed without a direction.")
        }

        // 2. Get Current Location data
        let currentLocationID = await engine.playerLocationID()
        guard let currentLoc = await engine.locationSnapshot(with: currentLocationID) else {
            throw ActionError.internalEngineError("Player's current location ID '\(currentLocationID)' is invalid.")
        }

        // 3. Find Exit
        guard let exit = currentLoc.exits[direction] else {
            throw ActionError.invalidDirection // Standard message: "You can't go that way."
        }

        // 4. Check Exit Conditions
        if exit.isDoor {
            if !exit.isOpen {
                 // Maybe use exit.blockedMessage if available?
                throw ActionError.directionIsBlocked("The \(direction.rawValue) door is closed.")
            }
            if exit.isLocked {
                throw ActionError.directionIsBlocked("The \(direction.rawValue) door seems to be locked.")
            }
        }

        // TODO: Check requiredKey
        // if let keyID = exit.requiredKey {
        //     guard await engine.playerHasItem(keyID) else {
        //         throw ActionError.directionIsBlocked(exit.blockedMessage ?? "You lack the required key.")
        //     }
        // }

        // Use generic blocked message if provided and conditions not met otherwise
        if let blockedMessage = exit.blockedMessage {
            // TODO: Add more sophisticated condition checking here if needed
            // For now, assume if message exists, it blocks unless handled above
            throw ActionError.directionIsBlocked(blockedMessage)
        }

        // --- Movement Successful ---

        // 5. Update Player Location
        await engine.updatePlayerLocation(newLocationID: exit.destination)

        // 6. Describe New Location
        // The GameEngine loop usually handles describing the location after a successful turn.
        // However, explicitly calling it here ensures it happens immediately after movement.
        await engine.describeCurrentLocation()

        // 7. Output Message (Optional)
        // Often, just the new location description is sufficient output for movement.
        // await engine.ioHandler.print("You go \(direction.rawValue).")
    }
}
