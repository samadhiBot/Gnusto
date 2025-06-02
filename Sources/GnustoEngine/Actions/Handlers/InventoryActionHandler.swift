import Foundation

/// Handles the "INVENTORY" command (and its common synonym "I"), displaying a list
/// of items currently carried by the player.
public struct InventoryActionHandler: ActionHandler {
    /// Validates the "INVENTORY" command.
    /// This action typically requires no specific validation.
    public func validate(context: ActionContext) async throws {
        // No specific validation needed for basic inventory command.
    }

    /// Processes the "INVENTORY" command.
    ///
    /// This action retrieves all items currently parented to the player from the `GameState`.
    /// It then formats these items into a list for display. If the player is carrying nothing,
    /// a message indicating they are empty-handed is shown.
    /// This action does not typically consume game time or cause state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the list of carried items or a message
    ///   indicating an empty inventory.
    public func process(context: ActionContext) async throws -> ActionResult {
        // 1. Get inventory item snapshots
        let inventoryItems = await context.engine.items(in: .player)

        // 2. Construct the message
        if inventoryItems.isEmpty {
            return ActionResult("You are empty-handed.")
        } else {
            // 3. List Items
            let itemList = inventoryItems.sorted().map {
                "- \($0.withIndefiniteArticle.capitalizedFirst)"
            }.joined(separator: "\n")
            return ActionResult(
                """
                You are carrying:
                \(itemList.indent())
                """
            )
        }

        // Inventory command typically takes no game time.
        // No state changes occur.
    }
}
