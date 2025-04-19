import Foundation

/// Handles the "CLOSE" command.
public struct CloseActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.output("Close what?") // Consistent prompt
            return
        }

        // 2. Check if item exists and is accessible
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // Inline reachability check (copied from OpenActionHandler)
        let currentLocationID = await engine.playerLocationID()
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
            let isParentItemInReach = (parentParent == .location(currentLocationID) || parentParent == .player)
            if isParentItemInReach {
                 if parentItem.hasProperty(.surface) || (parentItem.hasProperty(.container) && parentItem.hasProperty(.open)) {
                    isReachable = true
                }
            }
        case .player:
            isReachable = true
        case .nowhere:
            isReachable = false
        }
        guard isReachable else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check if item is closeable (using .openable for now)
        guard targetItem.hasProperty(.openable) else {
            // Use the specific error for close attempts
            throw ActionError.itemNotCloseable(targetItemID)
        }

        // 4. Check if already closed
        guard targetItem.hasProperty(.open) else {
            // Zork used dummy messages; let's be specific.
            throw ActionError.itemAlreadyClosed(targetItemID)
        }

        // 5. Perform Close Action
        await engine.updateItemProperties(itemID: targetItemID, adding: .touched, removing: .open)

        // 6. Output Message
        // If an object handler handled the action (returned true), execute won't call this.
        // If it returned false, we *always* print the default message.
        await engine.output("You close the \(targetItem.name).")
    }
}

// TODO: Add/verify ActionError cases: .itemNotCloseable, .itemAlreadyClosed
