import Foundation

/// Handles the "INVENTORY" command and its synonyms (e.g., "I").
public struct InventoryActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(command: Command, engine: GameEngine) async throws {
        // No specific validation needed for basic inventory command.
    }

    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // 1. Get inventory item snapshots
        let inventoryItems = await engine.itemSnapshots(withParent: .player)

        // 2. Construct the message
        let message: String
        if inventoryItems.isEmpty {
            // TODO: Check Zork/classic message
            message = "You are empty-handed."
        } else {
            // 3. List Items
            // TODO: Check Zork/classic message format
            var messageParts = ["You are carrying:"]
            for item in inventoryItems.sorted() {
                messageParts.append("  A \(item.name)") // TODO: Improve listing format
            }
            message = messageParts.joined(separator: "\n")
        }

        // Inventory command typically takes no game time.
        // No state changes occur.
        return ActionResult(
            success: true,
            message: message
            // stateChanges and sideEffects default to empty
        )
    }
}
