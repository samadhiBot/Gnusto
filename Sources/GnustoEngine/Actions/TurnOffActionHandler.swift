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
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
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
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
             // Should be caught by validate
            throw ActionError.internalEngineError("Target item '\(targetItemID)' disappeared between validate and process for TURN OFF.")
        }

        // --- State Changes ---
        var stateChanges: [StateChange] = []

        // Add touched property if not present
        if !targetItem.hasProperty(.touched) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(targetItem.properties),
                newValue: .itemProperties(targetItem.properties.union([.touched]))
            ))
        }

        // Remove .on property
        stateChanges.append(StateChange(
            entityId: .item(targetItemID),
            propertyKey: .itemProperties,
            oldValue: .itemProperties(targetItem.properties.union(stateChanges.isEmpty ? [] : [.touched])), // Old value includes touched if added
            newValue: .itemProperties(targetItem.properties.union(stateChanges.isEmpty ? [] : [.touched]).subtracting([.on]))
        ))

        // --- Determine Message ---
        var messageParts: [String] = []
        messageParts.append("The \(targetItem.name) is now off.")

        // Check if location became dark
        let isLightSource = targetItem.hasProperty(.lightSource)
        if isLightSource {
            let currentLocationID = await engine.playerLocationID()
            // Check lit status *after* applying potential state changes (hypothetically)
            // This requires simulating the state change effect on the light source.
            // A simpler approach is to check the *current* lit status and assume the handler
            // turning off the light *might* make it dark, then let the engine's main loop
            // re-describe the location which will handle the darkness message if needed.
            // For now, just return the primary message.
        }

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: messageParts.joined(separator: "\n"),
            stateChanges: stateChanges
        )
    }
}
