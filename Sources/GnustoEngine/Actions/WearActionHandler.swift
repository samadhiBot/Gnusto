import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON").
public struct WearActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = command.directObject else {
            await engine.ioHandler.print("Wear what?")
            return
        }

        // 2. Check if the item exists and is held by the player
        guard let targetItem = await engine.itemSnapshot(with: targetItemID),
              targetItem.parent == .player else {
            // If item doesn't exist OR isn't held, throw itemNotHeld
            throw ActionError.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is wearable
        guard targetItem.hasProperty(.wearable) else {
            // Throw the specific error for tests
            throw ActionError.itemNotWearable(targetItemID)
        }

        // 4. Check if already worn
        if targetItem.hasProperty(.worn) {
            // Use item name in the message
            await engine.ioHandler.print("You are already wearing the \(targetItem.name).")
            return
        }

        // 5. Update State - Add .worn property (parent remains .player)
        await engine.updateItemProperties(itemID: targetItemID, adding: .worn, .touched)

        // 6. Output Message
        await engine.ioHandler.print("You put on the \(targetItem.name).")
    }
}
