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

        // 2. Get target item state
        guard let targetItem = await engine.itemSnapshot(with: targetItemID) else {
            throw ActionError.internalEngineError("Parser resolved item ID '\(targetItemID)' which does not exist.")
        }

        // 3. Check if player is holding the item (parser should enforce this via .held condition)
        guard targetItem.parent == .player else {
            // This message might vary in originals, Zork often said "You don't have that."
            await engine.ioHandler.print("You need to be holding the \(targetItem.name) to wear it.")
            return
        }

        // 4. Check if item is wearable
        guard targetItem.hasProperty(.wearable) else {
            // Zork: "Putting on the <noun> would be difficult, to say the least."
            await engine.ioHandler.print("You can't wear the \(targetItem.name).")
            return
        }

        // 5. Check if already worn
        if targetItem.hasProperty(.worn) {
            // Zork: "You are already wearing the <noun>!"
            await engine.ioHandler.print("You are already wearing that.")
            return
        }

        // 6. Update State - Add .worn property (parent remains .player)
        await engine.addItemProperty(itemID: targetItemID, property: .worn)
        await engine.addItemProperty(itemID: targetItemID, property: .touched)

        // 7. Output Message
        // Zork: "You are now wearing the <noun>."
        await engine.ioHandler.print("You put on the \(targetItem.name).")
    }
}
