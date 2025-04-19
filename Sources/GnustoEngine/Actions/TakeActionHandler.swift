import Foundation

/// Handles the "TAKE" command and its synonyms (e.g., "GET").
public struct TakeActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.output("Take what?")
            // Consider throwing ActionError.prerequisiteNotMet("Direct object required.")
            return
        }

        // 2. Get target item state and current location
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }
        let currentLocationID = await engine.playerLocationID()

        // 3. Check if player already has the item
        if targetItem.parent == .player {
            await engine.output("You already have that.")
            return
        }

        // 4. Check reachability (item must be in the current location OR an accessible open container/surface)
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID):
            guard let parentItem = await engine.itemSnapshot(with: parentItemID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent parent item \(parentItemID).")
            }
            let parentParent = parentItem.parent
            let isParentItemAccessible = (parentParent == .location(currentLocationID) || parentParent == .player)

            if isParentItemAccessible {
                if parentItem.hasProperty(.surface) {
                    isReachable = true
                } else if parentItem.hasProperty(.container) {
                    guard parentItem.hasProperty(.open) else {
                        throw ActionError.containerIsClosed(parentItemID)
                    }
                    isReachable = true
                } else {
                    // Trying to take from something not open/surface
                    // Use a generic error? Or specific? Let's refine.
                    throw ActionError.prerequisiteNotMet("You can't take things out of the \(parentItem.name).")
                    // Old code: await engine.ioHandler.print("..."); return
                }
            }
        case .player:
            // Should have been caught by the "already have" check
            throw ActionError.internalEngineError("Item parent is player but wasn't caught earlier.")
            // Old code: await engine.ioHandler.print("...", style: .debug); return
        case .nowhere:
            isReachable = false
        }

        guard isReachable else {
            // Throw the correct error for existing but unreachable items
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 5. Check if the item is takable
        guard targetItem.hasProperty(.takable) else {
            throw ActionError.itemNotTakable(targetItemID)
        }

        // 6. Check capacity
        guard await engine.canPlayerCarry(itemSize: targetItem.size) else {
            throw ActionError.playerCannotCarryMore
        }

        // 7. Update State
        await engine.updateItemParent(itemID: targetItemID, newParent: .player)
        // Pass property directly as variadic args
        await engine.updateItemProperties(itemID: targetItemID, adding: .touched)
        // Add pronoun update using the dedicated engine method
        await engine.updatePronounReference(pronoun: "it", itemID: targetItemID)

        // 8. Output Message
        await engine.output("Taken.")
    }
}
