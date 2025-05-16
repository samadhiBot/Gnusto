import Foundation

/// Handles the "INVENTORY" context.command and its synonyms (e.g., "I").
public struct InventoryActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // No specific validation needed for basic inventory context.command.
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // 1. Get inventory item snapshots
        let inventoryItems = await context.engine.items(in: .player)

        // 2. Construct the message
        if inventoryItems.isEmpty {
            return ActionResult("You are empty-handed.")
        } else {
            // 3. List Items
            // TODO: Check Zork/classic message format
            let itemList = inventoryItems.sorted().map {
                "  - \($0.withIndefiniteArticle.capitalizedFirst)"
            }.joined(separator: "\n")
            return ActionResult(
                """
                You are carrying:
                \(itemList.indent())
                """
            )
        }

        // Inventory context.command typically takes no game time.
        // No state changes occur.

    }
}
