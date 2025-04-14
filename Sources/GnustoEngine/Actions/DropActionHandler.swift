import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN").
public struct DropActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.ioHandler.print("Drop what?")
            return
        }

        // 2. Get target item state and current location
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            // Should ideally be caught by parser ensuring item exists
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }
        let currentLocationID = await engine.playerLocationID()

        // 3. Check if player is holding the item
        guard targetItem.parent == .player else {
            // TODO: Check Zork/classic message for this
            await engine.ioHandler.print("You aren't holding that.")
            return
        }

        // 4. Update State
        await engine.updateItemParent(itemID: targetItemID, newParent: .location(currentLocationID))
        // If item was worn, it is no longer worn when dropped
        if targetItem.hasProperty(.worn) {
            await engine.removeItemProperty(itemID: targetItemID, property: .worn)
        }
        // Ensure item is marked touched after dropping
        await engine.addItemProperty(itemID: targetItemID, property: .touched)

        // 5. Output Message
        // TODO: Check Zork/classic message for this
        await engine.ioHandler.print("Dropped.")
    }
}
