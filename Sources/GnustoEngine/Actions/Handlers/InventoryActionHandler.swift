import Foundation

/// Handles the "INVENTORY" command (and its common synonym "I"), displaying a list
/// of items currently carried by the player.
public struct InventoryActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .inventory

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [String] = ["i"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods
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
        // Get inventory item snapshots
        let inventoryItems = await context.engine.items(in: .player)

        // Construct the message
        var message: String {
            if inventoryItems.isEmpty {
                return context.message.youAreEmptyHanded()
            } else {
                let itemList = inventoryItems.sorted().map {
                    "- \($0.withIndefiniteArticle.capitalizedFirst)"
                }.joined(separator: "\n")
                return """
                    \(context.message.youAreCarrying())
                    \(itemList.indent())
                    """
            }
        }

        return ActionResult(message)
    }
}
