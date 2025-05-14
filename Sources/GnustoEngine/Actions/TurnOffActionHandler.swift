import Foundation

/// Handles the "TURN OFF" action for items, primarily light sources.
struct TurnOffActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
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

    func process(context: ActionContext) async throws -> ActionResult {
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
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // Change 2: Remove .on property change (only if currently on)
        if targetItem.attributes[.isOn] == true {
            stateChanges.append(StateChange(
                entityID: .item(targetItem.id),
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
