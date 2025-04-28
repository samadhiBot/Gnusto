import Foundation

/// Handles the "TURN ON" action for items, primarily light sources.
struct TurnOnActionHandler: ActionHandler {
    func perform(
        command: Command,
        engine: GameEngine
        // ioHandler is accessed via engine
    ) async throws {
        // 1. Get direct object ID from command.
        guard let targetItemID = command.directObject else {
            // Zork: "Turn on what?"
            await engine.ioHandler.print("Turn on what?")
            return // Not an error, just needs clarification
        }

        // 2. Fetch the item snapshot.
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // 3. Verify the item is reachable.
        // Special case: Allow turning on a light source in the current location even if dark.
        let currentLocationID = await engine.playerLocationID()
        let isHeld = targetItem.parent == .player
        let isInLocation = targetItem.parent == .location(currentLocationID)
        let isLight = targetItem.hasProperty(.lightSource)
        let roomIsDark = !(await engine.scopeResolver.isLocationLit(locationID: currentLocationID))

        var isNormallyReachable = false
        if isHeld {
            isNormallyReachable = true
        } else if isInLocation {
            // Check standard reachability only if the room isn't dark or if it isn't a light source
            if !roomIsDark || !isLight {
                let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
                isNormallyReachable = reachableItems.contains(targetItemID)
            } else {
                // It's a light source in a dark room - allow interaction
                isNormallyReachable = true
            }
        } // If not held or in location, it's definitely not reachable

        guard isNormallyReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Mark as touched regardless of outcome (standard Zork behavior)
        await engine.applyItemPropertyChange(itemID: targetItemID, adding: [.touched])

        // 4. Check if the item has the `.device` property.
        // Zork V-LAMP-ON checks LIGHTBIT first, but let's check device for broader applicability.
        // This differs slightly from Zork 1 but makes sense for a general engine.
        // TODO: Revisit if we need a separate verb for non-light devices.
        guard targetItem.hasProperty(.device) else {
            // Zork: "You can't turn that on."
            throw ActionError.prerequisiteNotMet("You can't turn that on.") // Use generic failure
        }

        // 5. Check if the item already has the `.on` property.
        if targetItem.hasProperty(.on) {
            // Zork V-LAMP-ON: "It is already on."
            await engine.ioHandler.print("It's already on.")
            return
        }

        // 6. Check if it's specifically a light source (for room illumination logic)
        let isLightSource = targetItem.hasProperty(.lightSource)

        // Capture current lit status before turning on
        let wasLit = await engine.scopeResolver.isLocationLit(locationID: currentLocationID)

        // 7. Add the `.on` property to the item.
        await engine.applyItemPropertyChange(itemID: targetItemID, adding: [.on])

        // 8. Print "You turn the [item name] on."
        // Zork V-LAMP-ON: "The brass lantern is now on."
        await engine.ioHandler.print("The \(targetItem.name) is now on.")

        // 9. Check if the location was previously dark and is now lit.
        // Only describe the location if it was dark AND the item turned on is a light source.
        if isLightSource {
            let isNowLit = await engine.scopeResolver.isLocationLit(locationID: currentLocationID)
            if !wasLit && isNowLit {
                await engine.describeCurrentLocation()
            }
        }
    }
}
