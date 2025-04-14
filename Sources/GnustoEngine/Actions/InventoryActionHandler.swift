import Foundation

/// Handles the "INVENTORY" command and its synonyms (e.g., "I").
public struct InventoryActionHandler: ActionHandler {

    public init() {}

    public func perform(command: Command, engine: GameEngine) async throws {
        // 1. Get inventory item snapshots
        let inventoryItems = await engine.itemSnapshots(withParent: .player)

        // 2. Check if empty
        if inventoryItems.isEmpty {
            // TODO: Check Zork/classic message
            await engine.ioHandler.print("You are empty-handed.")
        } else {
            // 3. List Items
            // TODO: Check Zork/classic message format
            await engine.ioHandler.print("You are carrying:")
            for item in inventoryItems {
                // Basic listing, could be enhanced with articles, descriptions etc.
                await engine.ioHandler.print("  A \(item.name)")
            }
        }
        // Inventory command typically takes no game time / turn count doesn't increment
        // This should be handled by the GameEngine loop logic if desired.
    }
}
