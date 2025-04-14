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
        case .item(let containerID):
            // Item is in a container. Check if container is accessible and open.
            guard let containerItem = await engine.itemSnapshot(with: containerID) else {
                throw ActionError.internalEngineError("Item \(targetItemID) references non-existent container \(containerID).")
            }
            // Is the container itself in the room or held by the player?
            let containerParent = containerItem.parent
            let isContainerAccessible = (containerParent == .location(currentLocationID) || containerParent == .player)

            if isContainerAccessible {
                // Is it actually an open container?
                guard containerItem.hasProperty(.container) else {
                    // Trying to take something 'from' a non-container
                    await engine.ioHandler.print("You can't take things out of the \(containerItem.name).")
                    return
                }
                guard containerItem.hasProperty(.open) else {
                    // Container is closed
                    throw ActionError.containerIsClosed(containerID)
                }
                // If accessible and open, the item within is reachable
                isReachable = true
            }
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
        var wasWorn = false // Flag to change output message
        await engine.updateItemParent(itemID: targetItemID, newParent: .player)
        await engine.addItemProperty(itemID: targetItemID, property: .touched)
        if targetItem.hasProperty(.wearable) {
            await engine.addItemProperty(itemID: targetItemID, property: .worn)
            wasWorn = true
        }

        // 8. Output Message
        let message = wasWorn ? "Taken (and worn)." : "Taken."
        await engine.ioHandler.print(message)
    }
}
