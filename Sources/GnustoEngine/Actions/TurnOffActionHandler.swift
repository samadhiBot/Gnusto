import Foundation

/// Handles the "TURN OFF" action for items, primarily light sources.
struct TurnOffActionHandler: EnhancedActionHandler {

    // MARK: - EnhancedActionHandler Methods

    func validate(command: Command, engine: GameEngine) async throws {
        // 1. Get direct object ID
        guard let targetItemID = command.directObject else {
            throw ActionError.customResponse("Turn off what?")
        }

        // 2. Fetch the item snapshot.
        guard let targetItem = await engine.item(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID.rawValue)'.")
        }

        // 3. Verify the item is reachable.
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item has the `.device` property.
        guard targetItem.hasProperty(.device) else {
            throw ActionError.prerequisiteNotMet("You can't turn that off.")
        }

        // 5. Check if the item is already off (lacks `.on`).
        guard targetItem.hasProperty(.on) else {
            throw ActionError.customResponse("It's already off.") // Use customResponse
        }
    }

    func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObject else {
            throw ActionError.internalEngineError("TURN OFF command reached process without direct object.")
        }
        guard let targetItem = await engine.item(with: targetItemID) else {
             // Should be caught by validate
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process for TURN OFF.")
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

        // Remove .on property change (always based on initial state + touched)
        let propertiesAfterTouch = initialProperties.union(stateChanges.isEmpty ? [] : [.touched]) // Account for potential touch
        let propertiesAfterOff = propertiesAfterTouch.subtracting([.on])
        // Only add the change if .on was actually present initially
        if initialProperties.contains(.on) { // Ensure we only remove if it was on
             stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                 // Old value depends on whether touched was added *before* this change conceptually
                oldValue: .itemPropertySet(propertiesAfterTouch),
                newValue: .itemPropertySet(propertiesAfterOff)
            ))
        }

        // --- Determine Message ---
        var messageParts: [String] = []
        messageParts.append("The \(targetItem.name) is now off.")

        // Check if location became dark
        let isLightSource = targetItem.hasProperty(.lightSource)
        if isLightSource {
            let currentLocationID = await engine.gameState.player.currentLocationID

            // Determine the hypothetical state of the target item *after* changes
            var propsAfterOff = targetItem.properties // Start with current props
            propsAfterOff.remove(.on)
            if !targetItem.hasProperty(.touched) {
                propsAfterOff.insert(.touched)
            }

            // Check lit status using the hypothetical state of the single changed item
            let locationIsNowLit = await engine.scopeResolver.isLocationLitAfterSimulatedChange(
                locationID: currentLocationID,
                changedItemID: targetItemID,
                newItemProperties: propsAfterOff // Pass the hypothetical properties
            )

            if !locationIsNowLit {
                messageParts.append("It is now pitch black. You are likely to be eaten by a grue.")
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
