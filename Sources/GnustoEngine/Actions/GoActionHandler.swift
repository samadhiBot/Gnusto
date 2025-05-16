import Foundation

/// Handles movement context.commands (e.g., "GO NORTH", "NORTH", "N").
public struct GoActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Identify Direction
        guard let direction = context.command.direction else {
            throw ActionResponse.prerequisiteNotMet("Go where?")
        }

        // 2. Get Current Location data
        let currentLocationID = await context.engine.playerLocationID
        let currentLocation = try await context.engine.location(currentLocationID)

        // 3. Find Exit
        guard let exit = currentLocation.exits[direction] else {
            throw ActionResponse.invalidDirection // Standard message: "You can't go that way."
        }

        // 4. Check Exit Conditions

        // Check for static blocked message first
        if let staticBlockedMessage = exit.blockedMessage {
            throw ActionResponse.directionIsBlocked(staticBlockedMessage)
        }

        // Continue if exit is a door, otherwise validation is done
        guard let doorID = exit.doorID else { return }
        let door = try await context.engine.item(doorID)

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
        let currentLocation = try await context.engine.playerLocation()
        guard
            let direction = context.command.direction,
            let exit = currentLocation.exits[direction]
        else {
            // Should not happen if validate passed, but defensive check
            throw ActionResponse.internalEngineError(
                "Exit disappeared between validate and process for GO context.command."
            )
        }
        let destination = try await context.engine.location(exit.destinationID)

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
        if let update = await context.engine.setFlag(.isVisited, on: destination) {
            stateChanges.append(update)
        }

        // --- Create Result ---
        // Movement itself doesn't usually print a message; the new location description suffices.
        // The context.engine's run loop will trigger describeCurrentLocation after state changes.
        return ActionResult(stateChanges: stateChanges)
    }
}
