import Foundation

/// Handles the "TOUCH" command and its synonyms (e.g., "FEEL", "RUB", "PAT").
public struct TouchActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            // Zork 1 doesn't seem to have a specific verb for TOUCH/FEEL,
            // so we invent a reasonable prompt.
            await engine.output("Touch what?")
            return
        }

        // 2. Check if item exists and is accessible
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // If parser resolved an ID that doesn't exist in state.
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }

        // Check reachability (copied & adapted from TakeActionHandler)
        let currentLocationID = await engine.playerLocationID()
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            // Item is directly in a location
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID):
            // Item is inside/on another item
            guard let parentItem = await engine.itemSnapshot(with: parentItemID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent parent item \(parentItemID).")
            }
            let parentParent = parentItem.parent
            let isParentItemInReach = (parentParent == .location(currentLocationID) || parentParent == .player)

            if isParentItemInReach {
                // Can touch items inside/on accessible open containers or surfaces
                if parentItem.hasProperty(.surface) {
                    isReachable = true
                } else if parentItem.hasProperty(.container) {
                    // Note: Unlike TAKE, TOUCH might work on closed containers?
                    // For now, require it to be open for simplicity, matching TAKE.
                    // Consider relaxing this later if needed.
                    guard parentItem.hasProperty(.open) else {
                        // Consider a different error? .itemNotAccessible might imply the container itself isn't there.
                        // Let's use prerequisiteNotMet for now.
                        throw ActionError.prerequisiteNotMet("The \(parentItem.name) is closed.")
                    }
                    isReachable = true
                } // Items inside non-container/non-surface items are generally not reachable
            }
        case .player:
            // Item is held by the player
            isReachable = true
        case .nowhere:
            // Item is not in the world
            isReachable = false
        }

        guard isReachable else {
            // Use the error case for items that exist but aren't in scope
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Perform the action
        // Set the touched property, even if no other action occurs.
        await engine.updateItemProperties(itemID: targetItemID, adding: .touched)
        // TODO: Allow item-specific touch actions to override this default.
        // This might involve calling a function on the item or checking for
        // a specific property/component in a more advanced component system.

        // 4. Output default message (based on Zork 1 having no specific V?TOUCH/V?FEEL)
        await engine.output("You feel nothing special.")
    }
}
