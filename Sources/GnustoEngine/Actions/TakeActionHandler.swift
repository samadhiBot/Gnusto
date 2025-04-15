import Foundation

/// Handles the "TAKE" command and its synonyms (e.g., "GET").
public struct TakeActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            // This should ideally be caught by the parser requiring an object for TAKE
            await engine.ioHandler.print("Take what?")
            return // Not an error, just ambiguous input
        }

        // 2. Get target item state and current location
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // This indicates a parsing error or inconsistent state
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }
        let currentLocationID = await engine.playerLocationID()

        // 3. Check if player already has the item
        if targetItem.parent == .player {
            await engine.ioHandler.print("You already have that.")
            return
        }

        // 4. Check reachability (item must be in the current location OR an accessible open container)
        let itemParent = targetItem.parent
        var isReachable = false
        switch itemParent {
        case .location(let locID):
            isReachable = (locID == currentLocationID)
        case .item(let parentItemID): // Renamed from containerID for clarity
            // Item's parent is another item. Check if that parent is accessible and if the item can be taken from it.
            guard let parentItem = await engine.itemSnapshot(with: parentItemID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent parent item \(parentItemID).")
            }
            // Is the parent item itself in the room or held by the player?
            let parentParent = parentItem.parent
            let isParentItemAccessible = (parentParent == .location(currentLocationID) || parentParent == .player)

            if isParentItemAccessible {
                // Check if the parent is a surface (like a table or hook)
                if parentItem.hasProperty(.surface) {
                    // Items on accessible surfaces are reachable
                    isReachable = true
                }
                // Check if the parent is an open container
                else if parentItem.hasProperty(.container) {
                    guard parentItem.hasProperty(.open) else {
                        // Container is closed
                        throw ActionError.containerIsClosed(parentItemID)
                    }
                    // If accessible and open, the item within is reachable
                    isReachable = true
                } else {
                    // Trying to take something 'from' an item that is neither a surface nor an open container
                    // Use a more general message or differentiate based on context if needed later
                    await engine.ioHandler.print("You can't take things from the \(parentItem.name).")
                    // isReachable remains false, handled by the guard below
                }
            }
            // If parent item is not accessible, isReachable remains false
        case .player:
            // Should have been caught by the "already have" check earlier
            await engine.ioHandler.print("Error: Item parent is player but wasn't caught earlier.", style: .debug)
            return
        case .nowhere:
            isReachable = false // Item is nowhere
        }

        guard isReachable else {
            // Use the item's name in the message
            await engine.ioHandler.print("You don't see the \(targetItem.name) here.")
            return // Not an error, just out of scope
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

        // 8. Output Message
        await engine.ioHandler.print("Taken.")
    }
}
