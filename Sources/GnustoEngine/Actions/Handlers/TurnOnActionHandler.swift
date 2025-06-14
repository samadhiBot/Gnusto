import Foundation

/// Handles the "TURN ON" command, allowing the player to activate items that are
/// considered devices (e.g., light sources).
public struct TurnOnActionHandler: ActionHandler {

    // MARK: - ActionHandler Methods

    /// Validates the "TURN ON" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to turn on).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item. A special case allows turning on a
    ///    light source that is in the current dark room, even if otherwise unreachable.
    /// 4. The item is either a device (can be turned on/off) or flammable (can be burned).
    /// 5. If it's a device, it's not already on.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `custom` (for "Turn on what?" or "It's already on."),
    ///           `prerequisiteNotMet` (if not an item, not a device, and not flammable),
    ///           `itemNotAccessible`.
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // 1. Get direct object and ensure it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Turn on what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only turn on items.")
        }

        // 2. Fetch the item snapshot.
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Verify the item is reachable (with light source exception in dark).
        let currentLocationID = await context.engine.playerLocationID
        let isHeld = targetItem.parent == .player
        let isInLocation = targetItem.parent == .location(currentLocationID)
        let isLightSource = targetItem.hasFlag(.isLightSource)
        let roomIsDark = await context.engine.playerLocationIsLit() == false

        var isReachable = false
        if isHeld {
            isReachable = true
        } else if isInLocation {
            // If it's a light source in a dark room, consider it reachable to turn on.
            if roomIsDark && isLightSource {
                isReachable = true
            } else {
                // Otherwise, standard reachability check.
                isReachable = await context.engine.playerCanReach(targetItemID)
            }
        }
        guard isReachable else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item is either a device or flammable.
        let isDevice = targetItem.hasFlag(.isDevice)
        let isFlammable = targetItem.hasFlag(.isFlammable)

        guard isDevice || isFlammable else {
            throw ActionResponse.prerequisiteNotMet("You can't turn that on.")
        }

        // 5. If it's a device, check if it's already on.
        if isDevice && targetItem.hasFlag(.isOn) {
            throw ActionResponse.custom("It's already on.")
        }
    }

    /// Processes the "TURN ON" command.
    ///
    /// This method intelligently handles both devices and flammable objects:
    /// - If the item is a device (has `.isDevice`), it turns the device on.
    /// - If the item is flammable but not a device (has `.isFlammable` but not `.isDevice`),
    ///   it delegates to burn logic.
    /// - If both, devices take precedence (lamps can be turned on, not burned).
    ///
    /// For devices, this action performs:
    /// 1. Retrieves the target item.
    /// 2. Ensures the `.isTouched` flag is set on the item.
    /// 3. Sets the `.isOn` flag on the item.
    /// 4. Returns an `ActionResult` with a confirmation message.
    ///
    /// If turning on the item illuminates a dark room, the game engine will automatically handle
    /// printing the room's description after this action completes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is not an item (this should
    ///           be caught by `validate`), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("TurnOn: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        let isDevice = targetItem.hasFlag(.isDevice)
        let isFlammable = targetItem.hasFlag(.isFlammable)

        // If it's flammable but not a device, delegate to burn logic
        if isFlammable && !isDevice {
            return try await processBurn(targetItem: targetItem, context: context)
        }

        // Otherwise, proceed with normal turn-on logic for devices

        // Check if room was dark before turning on the light
        let wasRoomDark = await context.engine.playerLocationIsLit() == false

        // --- State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Ensure `.isTouched` flag is set.
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 2: Set `.isOn` flag.
        // Validation ensures the item was off, so an update should always occur here.
        if let update = await context.engine.setFlag(.isOn, on: targetItem) {
            stateChanges.append(update)
        }

        // --- Determine Message ---
        var messageParts: [String] = []
        messageParts.append("The \(targetItem.name) is now on.")

        // Check if turning on this light source illuminated a dark room
        let isLightSource = targetItem.hasFlag(.isLightSource)
        if wasRoomDark && isLightSource {
            // Apply state changes temporarily to check if room becomes lit
            let tempGameState = await context.engine.gameState
            var updatedGameState = tempGameState

            // Apply the state changes to see the effect
            for change in stateChanges {
                try? updatedGameState.apply(change)
            }

            // Check if room is now lit with the updated state
            let currentLocation = try await context.engine.playerLocation()
            let locationIsInherentlyLit = currentLocation.hasFlag(.inherentlyLit)

            if !locationIsInherentlyLit {
                // Check if this light source or others now provide light
                let allItems = updatedGameState.items.values
                let activeLightSources = allItems.filter { item in
                    let isInPlayerInventory = item.parent == .player
                    let isInCurrentLocation = item.parent == .location(currentLocation.id)
                    let providesLight = item.hasFlag(.isLightSource)
                    let isOn = item.hasFlag(.isOn)
                    return (isInPlayerInventory || isInCurrentLocation) && providesLight && isOn
                }

                if !activeLightSources.isEmpty {
                    messageParts.append("You can see your surroundings now.")
                }
            }
        }

        // --- Create Result ---
        return ActionResult(
            message: messageParts.joined(separator: "\n"),
            stateChanges: stateChanges
        )
    }

    // MARK: - Helper Methods

    /// Processes the burn logic when a flammable (but non-device) item is "turned on".
    ///
    /// This method implements the same logic as `BurnActionHandler` for flammable items.
    /// It's called when the player uses "light" or "turn on" on a flammable object.
    ///
    /// - Parameters:
    ///   - targetItem: The flammable item to burn.
    ///   - context: The action context.
    /// - Returns: An `ActionResult` with burn-specific messaging and state changes.
    private func processBurn(targetItem: Item, context: ActionContext) async throws -> ActionResult {
        var stateChanges: [StateChange] = []

        // Ensure the item is marked as touched
        if let touchChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchChange)
        }

        // Update pronouns
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(pronounChange)
        }

        // Check if the item is flammable (should always be true in this context)
        if targetItem.hasFlag(.isFlammable) {
            // Move the item to nowhere (destroy it)
            let destroyChange = await context.engine.move(targetItem, to: .nowhere)
            stateChanges.append(destroyChange)

            return ActionResult(
                message: "The \(targetItem.name) catches fire and burns to ashes.",
                stateChanges: stateChanges
            )
        } else {
            // Fallback message for non-flammable items (shouldn't reach here due to validation)
            let message = "You can't burn the \(targetItem.name)."

            return ActionResult(
                message: message,
                stateChanges: stateChanges
            )
        }
    }
}
