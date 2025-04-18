import Foundation

/// Handles the "TURN OFF" action for items, primarily light sources.
struct TurnOffActionHandler: ActionHandler {
    func perform(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Get direct object ID from command.
        guard let targetItemID = command.directObject else {
            // Zork: "Turn off what?"
            await engine.output("Turn off what?")
            return
        }

        // 2. Fetch the item snapshot.
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Verify the item is reachable.
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Mark as touched
        await engine.addItemProperty(itemID: targetItemID, property: .touched)

        // 4. Check if the item has the `.device` property.
        // Similar to TURN ON, check .device for general applicability.
        guard targetItem.hasProperty(.device) else {
            // Zork: "You can't turn that off."
            throw ActionError.prerequisiteNotMet("You can't turn that off.")
        }

        // 5. Check if the item is already off (lacks `.on`).
        guard targetItem.hasProperty(.on) else {
            // Zork V-LAMP-OFF: "It is already off."
            await engine.output("It's already off.")
            return
        }

        // 6. Check if it's specifically a light source.
        let isLightSource = targetItem.hasProperty(.lightSource)

        // Capture current lit status before turning off
        let currentLocationID = await engine.playerLocationID()
        let wasLit = await engine.scopeResolver.isLocationLit(locationID: currentLocationID)

        // 7. Remove the `.on` property from the item.
        await engine.removeItemProperty(itemID: targetItemID, property: .on)

        // 8. Print "You turn the [item name] off."
        // Zork V-LAMP-OFF: "The brass lantern is now off."
        await engine.output("The \(targetItem.name) is now off.")

        // 9. Check if the location was previously lit and is now dark.
        // Only print pitch black message if it was lit AND the item turned off was a light source AND the room is now dark.
        if isLightSource {
            let isNowLit = await engine.scopeResolver.isLocationLit(locationID: currentLocationID)
            if wasLit && !isNowLit {
                // Zork V-LAMP-OFF standard darkness message
                await engine.output("It is now pitch black. You are likely to be eaten by a grue.")
            }
        }
    }
}
