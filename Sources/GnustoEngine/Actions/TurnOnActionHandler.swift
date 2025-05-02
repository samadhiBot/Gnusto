import Foundation

/// Handles the "TURN ON" action for items, primarily light sources.
struct TurnOnActionHandler: EnhancedActionHandler {

    // MARK: - EnhancedActionHandler Methods

    func validate(command: Command, engine: GameEngine) async throws {
        // 1. Get direct object ID
        guard let targetItemID = command.directObject else {
            throw ActionError.customResponse("Turn on what?")
        }

        // 2. Fetch the item snapshot.
        guard let targetItem = await engine.item(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Verify the item is reachable (with light source exception in dark).
        let currentLocationID = await engine.gameState.player.currentLocationID
        let isHeld = targetItem.parent == .player
        let isInLocation = targetItem.parent == .location(currentLocationID)
        let isLight = targetItem.hasProperty(.lightSource)
        let roomIsDark = !(await engine.scopeResolver.isLocationLit(locationID: currentLocationID))

        var isNormallyReachable = false
        if isHeld {
            isNormallyReachable = true
        } else if isInLocation {
            if !roomIsDark || !isLight {
                let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
                isNormallyReachable = reachableItems.contains(targetItemID)
            } else {
                isNormallyReachable = true // Allow turning on light in dark room
            }
        }
        guard isNormallyReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item has the `.device` property.
        guard targetItem.hasProperty(.device) else {
            throw ActionError.prerequisiteNotMet("You can't turn that on.")
        }

        // 5. Check if the item already has the `.on` property.
        if targetItem.hasProperty(.on) {
            throw ActionError.customResponse("It's already on.")
        }
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("TURN ON command reached process without direct object.")
        }
        guard let targetItem = await engine.item(with: targetItemID) else {
            // Should be caught by validate
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process for TURN ON.")
        }

        // --- State Changes ---
        var stateChanges: [StateChange] = []
        let initialProperties = targetItem.properties // Use initial state

        // Add touched property change if needed
        if !initialProperties.contains(.touched) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(initialProperties),
                newValue: .itemPropertySet(initialProperties.union([.touched]))
            ))
        }

        // Add .on property change (based on initial state + touched)
        let propertiesAfterTouch = initialProperties.union(stateChanges.isEmpty ? [] : [.touched])
        let propertiesAfterOn = propertiesAfterTouch.union([.on])
        // Only add the change if .on was not already present initially
        if !initialProperties.contains(.on) { // Ensure we only add if it was off
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                // Old value depends on whether touched was added *before* this change conceptually
                oldValue: .itemPropertySet(propertiesAfterTouch),
                newValue: .itemPropertySet(propertiesAfterOn)
            ))
        }

        // --- Determine Message ---
        let message = "The \(targetItem.name) is now on."

        // --- Side Effects (Optional) ---
        // Check if the room became lit. If so, the engine loop will describe it.
        // No explicit side effect needed here to trigger re-description.

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
