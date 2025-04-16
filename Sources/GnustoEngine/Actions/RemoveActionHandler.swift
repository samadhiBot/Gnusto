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

        // 2. Check if the item is held by the player
        guard let targetItem = await engine.itemSnapshot(with: targetItemID),
              targetItem.parent == .player else {
            // If item doesn't exist OR isn't held, throw itemNotHeld
            throw ActionError.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is currently worn
        guard targetItem.hasProperty(.worn) else {
            // Zork: "You are not wearing the <noun>!"
            // Use the correct wording from test failure
            await engine.ioHandler.print("You are not wearing the \(targetItem.name).")
            return
        }

        // 4. Update State - Remove .worn property (parent remains .player)
        await engine.removeItemProperty(itemID: targetItemID, property: .worn)
        // Mark as touched (implicitly happens when taken, should happen here too)
        await engine.addItemProperty(itemID: targetItemID, property: .touched)

        // 5. Output Message
        // Zork: "You remove the <noun>."
        await engine.ioHandler.print("You take off the \(targetItem.name).")
    }
}
