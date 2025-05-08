import Foundation

/// Handles movement context.commands (e.g., "GO NORTH", "NORTH", "N").
public struct GoActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Identify Direction
        guard let direction = context.command.direction else {
            throw ActionError.internalEngineError(
                "Go context.command processed without a direction."
            )
        }

        // 2. Get Current Location data
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        guard let currentLoc = await context.engine.location(with: currentLocationID) else {
            throw ActionError.internalEngineError(
                "Player's current location ID '\(currentLocationID)' is invalid."
            )
        }

        // 3. Find Exit
        guard let exit = currentLoc.exits[direction] else {
            throw ActionError.invalidDirection // Standard message: "You can't go that way."
        }

        // 4. Check Exit Conditions

        // Check for static blocked message first
        if let staticBlockedMessage = exit.blockedMessage {
            throw ActionError.directionIsBlocked(staticBlockedMessage)
        }

        // Continue if exit is a door, otherwise validation is done
        guard let doorID = exit.doorID else { return }

        guard let door = await context.engine.item(doorID) else {
            throw ActionError.internalEngineError("Exit specifies unknown door '\(doorID)'.")
        }

        // Check if the door is locked
        if door.hasFlag(.isLocked) {
            throw ActionError.directionIsBlocked("The \(door.name) is locked.")
        }

        // Check if the door is open
        if !door.hasFlag(.isOpen) {
            throw ActionError.directionIsBlocked("The \(direction.rawValue) door is closed.")
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // Validation passed, find exit again (state might have changed, though unlikely for exits)
        guard
            let direction = context.command.direction,
            let currentLoc = await context.engine.location(
                with: await context.engine.gameState.player.currentLocationID
            ),
            let exit = currentLoc.exits[direction]
        else {
            // Should not happen if validate passed, but defensive check
            throw ActionError.internalEngineError("Exit disappeared between validate and process for GO context.command.")
        }

        // --- Create State Change ---
        let oldLocationID = await context.engine.gameState.player.currentLocationID
        let newLocationID = exit.destination

        let change = StateChange(
            entityID: .player,
            attributeKey: .playerLocation,
            oldValue: .locationID(oldLocationID),
            newValue: .locationID(newLocationID)
        )

        // --- Create Result ---
        // Movement itself doesn't usually print a message; the new location description suffices.
        // The context.engine's run loop will trigger describeCurrentLocation after state changes.
        return ActionResult(
            success: true,
            message: "", // No specific message for GO action itself
            stateChanges: [change]
        )
    }
}
