import Foundation

/// Handles the "REMOVE" command and its synonyms (e.g., "DOFF", "TAKE OFF").
public struct RemoveActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.ioHandler.print("Remove what?")
            return
        }

        // 2. Get target item state
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }

        // 3. Check if item is currently worn (parser should enforce this via .worn condition)
        guard targetItem.hasProperty(.worn) else {
            // Zork: "You are not wearing the <noun>!"
            await engine.ioHandler.print("You aren't wearing the \(targetItem.name).")
            return
        }

        // 4. Check if item is actually held by the player (worn items have parent .player)
        guard targetItem.parent == .player else {
            throw ActionError.internalEngineError("Item '\(targetItemID)' has .worn property but is not held by player.")
        }

        // 5. Update State - Remove .worn property (parent remains .player)
        await engine.removeItemProperty(itemID: targetItemID, property: .worn)
        await engine.addItemProperty(itemID: targetItemID, property: .touched) // Mark as touched

        // 6. Output Message
        // Zork: "You remove the <noun>."
        await engine.ioHandler.print("You take off the \(targetItem.name).")
    }
}
