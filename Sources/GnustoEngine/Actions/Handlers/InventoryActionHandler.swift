import Foundation

/// Handles the "INVENTORY" command (and its common synonym "I"), displaying a list
/// of items currently carried by the player.
public struct InventoryActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let verbs: [VerbID] = [.inventory, "i"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "INVENTORY" command.
    ///
    /// This action retrieves all items currently parented to the player from the `GameState`.
    /// It then formats these items into a list for display. If the player is carrying nothing,
    /// a message indicating they are empty-handed is shown.
    /// This action does not typically consume game time or cause state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Get inventory item snapshots
        let inventoryItems = await engine.items(in: .player)

        // Construct the message
        let message: String
        if inventoryItems.isEmpty {
            message = engine.messenger.youAreEmptyHanded()
        } else {
            let itemList = inventoryItems.sorted().map {
                "- \($0.withIndefiniteArticle.capitalizedFirst)"
            }.joined(separator: "\n")
            message = """
                \(engine.messenger.youAreCarrying())
                \(itemList.indent())
                """
        }

        return ActionResult(message)
    }
}
