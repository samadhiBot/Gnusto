import Foundation

/// Handles the "TURN ON" action for items, primarily light sources.
struct TurnOnActionHandler: EnhancedActionHandler {

    // MARK: - EnhancedActionHandler Methods

    func validate(context: ActionContext) async throws {
        // 1. Get direct object ID
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Turn on what?")
        }

        // 2. Fetch the item snapshot.
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Verify the item is reachable (with light source exception in dark).
        let currentLocationID = await context.engine.gameState.player.currentLocationID
        let isHeld = targetItem.parent == .player
        let isInLocation = targetItem.parent == .location(currentLocationID)
        let isLight = targetItem.hasFlag(.isLightSource)
        let roomIsDark = !(await context.engine.scopeResolver.isLocationLit(locationID: currentLocationID))

        var isNormallyReachable = false
        if isHeld {
            isNormallyReachable = true
        } else if isInLocation {
            if !roomIsDark || !isLight {
                let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
                isNormallyReachable = reachableItems.contains(targetItemID)
            } else {
                isNormallyReachable = true // Allow turning on light in dark room
            }
        }
        guard isNormallyReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item has the `.device` property.
        guard targetItem.hasFlag(.isDevice) else {
            throw ActionError.prerequisiteNotMet("You can't turn that on.")
        }

        // 5. Check if the item already has the `.on` property.
        if targetItem.hasFlag(.isOn) {
            throw ActionError.customResponse("It's already on.")
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("TURN ON context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Should be caught by validate
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process for TURN ON.")
        }

        // --- State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .touched property change if needed
        if targetItem.attributes[.isTouched] != true {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // Change 2: Add .on property change (only if currently off)
        if targetItem.attributes[.isOn] != true {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                attributeKey: .itemAttribute(.isOn),
                oldValue: targetItem.attributes[.isOn] ?? false,
                newValue: true,
            ))
        }

        // --- Determine Message ---
        let message = "The \(targetItem.name) is now on."

        // --- Side Effects (Optional) ---
        // Check if the room became lit. If so, the context.engine loop will describe it.
        // No explicit side effect needed here to trigger re-description.

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
