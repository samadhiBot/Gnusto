import Foundation

/// Handles the "INVENTORY" command (and its common synonym "I"), displaying a list
/// of items currently carried by the player.
public struct InventoryActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.inventory, "i"]

    public let requiresLight: Bool = false

    public let consumesTurn: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "INVENTORY" command.
    ///
    /// This action retrieves all items currently parented to the player from the `GameState`.
    /// It then formats these items into a list for display. If the player is carrying nothing,
    /// a message indicating they are empty-handed is shown.
    /// This action does not typically consume game time or cause state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get inventory item snapshots
        let inventoryItems = await context.player.inventory

        // Construct the message
        let message: String
        if inventoryItems.isEmpty {
            message = context.msg.youAreEmptyHanded()
        } else {
            let itemList = await inventoryItems.sorted().asyncMap {
                await "- \($0.withIndefiniteArticle.capitalizedFirst)"
            }
            message = """
                \(context.msg.youAreCarrying())
                \(itemList.joined(separator: .linebreak).indent())
                """
        }

        return ActionResult(message)
    }
}
