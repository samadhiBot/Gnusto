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
            await engine.output("(already taken)")
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
            // Throw error instead of just printing
            throw ActionError.itemNotHeld(targetItemID) // Or a new .itemNotReachable?
            // Old code: await engine.ioHandler.print("..."); return
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
        await engine.addItemProperty(itemID: targetItemID, property: .touched)
        // Add pronoun update
        await engine.updateGameState { state in
            state.updatePronoun("it", referringTo: targetItemID)
        }

        // 8. Output Message
        await engine.output("Taken.")
    }
}
