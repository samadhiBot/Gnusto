import Foundation

/// Handles the "READ" command.
public struct ReadActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.ioHandler.print("Read what?") // Invented prompt
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

        // 3. Check if room is lit (unless item provides light)
        let isLit = await engine.scopeResolver.isLocationLit(locationID: currentLocationID)
        let providesLight = targetItem.hasProperty(.lightSource) && targetItem.hasProperty(.on)
        guard isLit || providesLight else {
            // TODO: Engine should translate this error to the Zork message
            throw ActionError.roomIsDark
        }

        // 4. Check if item is readable
        guard targetItem.hasProperty(.readable) else {
            // TODO: Engine should translate this error to Zork message: "How does one read a...?"
            throw ActionError.itemNotReadable(targetItemID)
        }

        // 5. Perform Read Action
        await engine.applyItemPropertyChange(itemID: targetItemID, adding: [.touched])

        // 6. Check if item has text
        guard let textToRead = targetItem.readableText, !textToRead.isEmpty else {
            await engine.ioHandler.print("There's nothing written on the \(targetItem.name).")
            return
        }

        // 7. Output Message (the actual text)
        await engine.ioHandler.print(textToRead) // Print the text directly
    }
}
