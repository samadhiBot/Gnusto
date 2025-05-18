import Foundation

/// Handles movement commands (e.g., "GO NORTH", "NORTH", "N"), allowing the player to navigate
/// between locations in the game world.
public struct GoActionHandler: ActionHandler {
    /// Validates the "GO" command (or its directional shorthand).
    ///
    /// This method ensures that:
    /// 1. A direction is specified in the command.
    /// 2. The player's current location has an exit in the specified direction.
    /// 3. If the exit has a static `blockedMessage`, that message is thrown as an error.
    /// 4. If the exit is guarded by a door (`doorID` is present):
    ///    a. The door item exists.
    ///    b. The door is not flagged as `.isLocked`.
    ///    c. The door is flagged as `.isOpen`.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (if no direction), `invalidDirection` (if no such exit),
    ///           `directionIsBlocked` (if statically blocked or door is locked/closed).
    ///           Can also throw errors from `context.engine.item()` or `context.engine.location()`.
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

    /// Processes the "GO" command.
    ///
    /// Assuming validation has passed, this action:
    /// 1. Retrieves the current location and the exit details for the specified direction.
    /// 2. Creates a `StateChange` to update the player's `currentLocationID` to the
    ///    destination of the exit.
    /// 3. If the destination location has not yet been visited, creates a `StateChange` to set
    ///    its `.isVisited` flag.
    /// 4. Returns an `ActionResult` containing these state changes. Typically, no direct message
    ///    is returned by this action, as the game engine will subsequently describe the new location.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with `StateChange`s to move the player and mark the new
    ///            location as visited.
    /// - Throws: `ActionResponse.internalEngineError` if the exit disappears between validation and
    ///           process, or errors from `context.engine.location()` / `context.engine.item()`.
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
