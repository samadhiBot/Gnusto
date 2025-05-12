import Foundation

/// Handles movement context.commands (e.g., "GO NORTH", "NORTH", "N").
public struct GoActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Identify Direction
        guard let direction = context.command.direction else {
            throw ActionResponse.prerequisiteNotMet("Go where?")
        }

        // 2. Get Current Location data
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        guard let currentLoc = await context.engine.location(currentLocationID) else {
            throw ActionResponse.internalEngineError(
                "Player's current location ID '\(currentLocationID)' is invalid."
            )
        }

        // 3. Find Exit
        guard let exit = currentLoc.exits[direction] else {
            throw ActionResponse.invalidDirection // Standard message: "You can't go that way."
        }

        // 4. Check Exit Conditions

        // Check for static blocked message first
        if let staticBlockedMessage = exit.blockedMessage {
            throw ActionResponse.directionIsBlocked(staticBlockedMessage)
        }

        // Continue if exit is a door, otherwise validation is done
        guard let doorID = exit.doorID else { return }

        guard let door = await context.engine.item(doorID) else {
            throw ActionResponse.internalEngineError("Exit specifies unknown door '\(doorID)'.")
        }

        // Check if the door is locked
        if door.hasFlag(.isLocked) {
            throw ActionResponse.directionIsBlocked("The \(door.name) is locked.")
        }

        // Check if the door is open
        if !door.hasFlag(.isOpen) {
            throw ActionResponse.directionIsBlocked("The \(direction.rawValue) door is closed.")
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // Validation passed, find exit again (state might have changed, though unlikely for exits)
        guard
            let direction = context.command.direction,
            let currentLocation = await context.engine.location(
                await context.engine.gameState.player.currentLocationID
            ),
            let exit = currentLocation.exits[direction],
            let destination = await context.engine.location(exit.destinationID)
        else {
            // Should not happen if validate passed, but defensive check
            throw ActionResponse.internalEngineError("Exit disappeared between validate and process for GO context.command.")
        }

        // Create state changes
        var stateChanges: [StateChange] = [
            StateChange(
                entityID: .player,
                attributeKey: .playerLocation,
                oldValue: .locationID(currentLocation.id),
                newValue: .locationID(exit.destinationID)
            )
        ]

        // Set isVisited flag for the new location if it hasn't been visited yet
        if let setIsVisited = await context.engine.flag(destination, with: .isVisited) {
            stateChanges.append(setIsVisited)
        }

        // --- Create Result ---
        // Movement itself doesn't usually print a message; the new location description suffices.
        // The context.engine's run loop will trigger describeCurrentLocation after state changes.
        return ActionResult(
            success: true,
            message: "", // No specific message for GO action itself
            stateChanges: stateChanges
        )
    }
}
