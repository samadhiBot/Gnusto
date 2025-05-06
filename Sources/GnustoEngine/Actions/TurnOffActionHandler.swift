import Foundation

/// Handles the "TURN OFF" action for items, primarily light sources.
struct TurnOffActionHandler: EnhancedActionHandler {

    // MARK: - EnhancedActionHandler Methods

    func validate(context: ActionContext) async throws {
        // 1. Get direct object ID
        guard let targetItemID = context.command.directObject else {
            throw ActionError.customResponse("Turn off what?")
        }

        // 2. Fetch the item snapshot.
        guard let targetItem = await context.engine.item(targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID.rawValue)'.")
        }

        // 3. Verify the item is reachable.
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item has the `.device` property.
        guard targetItem.hasFlag(.isDevice) else {
            throw ActionError.prerequisiteNotMet("You can't turn that off.")
        }

        // 5. Check if the item is already off (lacks `.on`).
        guard targetItem.hasFlag(.isOn) else {
            throw ActionError.customResponse("It's already off.")
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionError.internalEngineError("TURN OFF context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
             // Should be caught by validate
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process for TURN OFF.")
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

        // Change 2: Remove .on property change (only if currently on)
        if targetItem.attributes[.isOn] == true {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                attributeKey: .itemAttribute(.isOn),
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
            let currentLocationID = await context.engine.gameState.player.currentLocationID
            let currentLocation = await context.engine.location(with: currentLocationID)

            // 1. Is the room inherently lit?
            let locationIsInherentlyLit = currentLocation?.hasFlag(.inherentlyLit) ?? false

            if !locationIsInherentlyLit {
                // 2. Check for other active light sources (inventory or location)
                let allItems = await context.engine.gameState.items.values
                let otherActiveLightSources = allItems.filter { item in
                    guard item.id != targetItemID else { return false } // Exclude the item being turned off
                    let isInPlayerInventory = item.parent == .player
                    let isInCurrentLocation = item.parent == .location(currentLocationID)
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
            success: true,
            message: messageParts.joined(separator: "\n"),
            stateChanges: stateChanges
        )
    }
}
