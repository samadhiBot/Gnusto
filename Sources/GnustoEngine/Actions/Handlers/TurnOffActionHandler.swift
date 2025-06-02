import Foundation

/// Handles the "TURN OFF" command, allowing the player to deactivate items that are
/// considered devices (e.g., light sources).
public struct TurnOffActionHandler: ActionHandler {
    /// Validates the "TURN OFF" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to turn off).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item.
    /// 4. The item has the `.isDevice` flag set (indicating it can be turned on/off).
    /// 5. The item is not already off (i.e., it currently has the `.isOn` flag).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `custom` (for "Turn off what?" or "It's already off."),
    ///           `prerequisiteNotMet` (if not an item or not a device),
    ///           `itemNotAccessible`.
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Get direct object and ensure it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Turn off what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only turn off items.")
        }

        // 2. Fetch the item snapshot.
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Verify the item is reachable.
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item has the `.device` property.
        guard targetItem.hasFlag(.isDevice) else {
            throw ActionResponse.prerequisiteNotMet("You can't turn that off.")
        }

        // 5. Check if the item is already off (lacks `.on`).
        guard targetItem.hasFlag(.isOn) else {
            throw ActionResponse.custom("It's already off.")
        }
    }

    /// Processes the "TURN OFF" command.
    ///
    /// Assuming basic validation has passed (the item is a reachable device and is currently on),
    /// this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Ensures the `.isTouched` flag is set on the item.
    /// 3. Clears the `.isOn` flag on the item.
    /// 4. Constructs a message confirming the action (e.g., "The flashlight is now off.").
    /// 5. If the turned-off item was a light source and the current location becomes dark as a result
    ///    (i.e., the location is not inherently lit and no other active light sources are present),
    ///    appends the classic "It is now pitch black. You are likely to be eaten by a grue." message.
    /// 6. Returns an `ActionResult` with the constructed message and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is not an item (this should
    ///           be caught by `validate`), or errors from `context.engine` calls (e.g., fetching items
    ///           or player location).
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("TurnOff: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // --- State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .touched property change if needed
        if targetItem.attributes[.isTouched] != true {
            stateChanges.append(StateChange(
                entityID: .item(targetItem.id),
                attribute: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // Change 2: Remove .on property change (only if currently on)
        if targetItem.attributes[.isOn] == true {
            stateChanges.append(StateChange(
                entityID: .item(targetItem.id),
                attribute: .itemAttribute(.isOn),
                oldValue: true,
                newValue: false
            ))
        }

        // --- Determine Message ---
        var messageParts: [String] = []
        messageParts.append("The \(targetItem.name) is now off.")

        // Check if location became dark
        let isLightSourceBeingTurnedOff = targetItem.hasFlag(.isLightSource)
        if isLightSourceBeingTurnedOff {
            let currentLocation = try await context.engine.playerLocation()

            // 1. Is the room inherently lit?
            let locationIsInherentlyLit = currentLocation.hasFlag(.inherentlyLit)

            if !locationIsInherentlyLit {
                // 2. Check for other active light sources (inventory or location)
                let allItems = await context.engine.gameState.items.values
                let otherActiveLightSources = allItems.filter { item in
                    guard item.id != targetItem.id else { return false } // Exclude the item being turned off
                    let isInPlayerInventory = item.parent == .player
                    let isInCurrentLocation = item.parent == .location(currentLocation.id)
                    let providesLight = item.hasFlag(.isLightSource)
                    let isOn = item.hasFlag(.isOn)
                    return (isInPlayerInventory || isInCurrentLocation) && providesLight && isOn
                }

                if otherActiveLightSources.isEmpty {
                    messageParts.append("It is now pitch black. You are likely to be eaten by a grue.")
                }
            }
        }

        // --- Create Result ---
        return ActionResult(
            message: messageParts.joined(separator: "\n"),
            stateChanges: stateChanges
        )
    }
}
