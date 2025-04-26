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
            // Standard message: "You can't go that way."
            await engine.output("You can't go that way.")
            return // Stop processing
        }

        // 4. Check Exit Conditions

        // Check for static blocked message first (highest priority override)
        if let staticBlockedMessage = exit.blockedMessage {
            await engine.output(staticBlockedMessage)
            return // Stop processing
        }

        // Check required key
        if let keyID = exit.requiredKey {
            // Correct: Use an engine method to check inventory for concurrency safety
            let playerHasKey = await engine.playerHasItem(itemID: keyID)
            if !playerHasKey {
                // TODO: Check Zork message for lacking a key for a passage
                throw ActionError.directionIsBlocked("You lack the key required to pass.")
            }
        }

        // Check door status if applicable
        if exit.isDoor {
            if !exit.isOpen {
                // Standard message for closed door
                throw ActionError.directionIsBlocked("The \(direction.rawValue) door is closed.")
            }
            if exit.isLocked {
                // Standard message for locked door
                throw ActionError.directionIsBlocked("The \(direction.rawValue) door seems to be locked.")
            }
        }

        // --- Movement Successful ---

        // 5. Update Player Location using the engine method that triggers hooks
        await engine.changePlayerLocation(to: exit.destination)

        // 6. Describe New Location
        // The GameEngine loop usually handles describing the location after a successful turn.
        // However, explicitly calling it here ensures it happens immediately after movement.
        await engine.describeCurrentLocation()

        // 7. Output Message (Optional)
        // Often, just the new location description is sufficient output for movement.
        // await engine.ioHandler.print("You go \(direction.rawValue).")
    }
}
