import Foundation

/// Handles the "OPEN" command.
public struct OpenActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.output("Open what?") // Zork-like prompt
            return
        }

        // 2. Check if item exists and is accessible
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved non-existent item ID '\(targetItemID)'.")
        }

        // Inline reachability check (adapted from TouchActionHandler)
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
                    isReachable = true // Can reach things on surfaces or in open containers
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

        // 3. Check if item is openable
        guard targetItem.hasProperty(.openable) else {
            throw ActionError.itemNotOpenable(targetItemID)
        }

        // 4. Check if already open
        guard !targetItem.hasProperty(.open) else {
            // Zork used dummy messages; let's be specific.
            throw ActionError.itemAlreadyOpen(targetItemID)
        }

        // 5. Check if locked
        // If it has .locked, it implies it is lockable for now.
        if targetItem.hasProperty(.locked) {
            // Default message, as Zork's was specific (e.g., "locked from above")
            throw ActionError.itemIsLocked(targetItemID)
        }

        // 6. Perform Open Action
        await engine.addItemProperty(itemID: targetItemID, property: .open)
        await engine.addItemProperty(itemID: targetItemID, property: .touched) // Opening implies touching

        // Call the hook, if any
        let hookHandled = await engine.onOpenItem?(engine, targetItemID) ?? false

        // 7. Output Message (if not handled by hook)
        if !hookHandled {
            await engine.output("You open the \(targetItem.name).")
        }
    }
}

// TODO: Add/verify ActionError cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
