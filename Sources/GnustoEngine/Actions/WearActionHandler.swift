import Foundation

/// Handles the "WEAR" context.command and its synonyms (e.g., "DON").
public struct WearActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Wear what?")
        }

        // 2. Check if the item exists and is held by the player
        guard let targetItem = await context.engine.item(targetItemID),
              targetItem.parent == .player else
        {
            throw ActionError.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is wearable
        guard targetItem.hasFlag(.isWearable) else {
            throw ActionError.itemNotWearable(targetItemID)
        }

        // 4. Check if already worn
        guard !targetItem.hasFlag(.isWorn) else {
            throw ActionError.itemIsAlreadyWorn(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        // IDs and validation guaranteed by validate()
        let targetItemID = context.command.directObject!
        guard let itemSnapshot = await context.engine.item(targetItemID) else {
            // Should not happen if validate passed
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for WEAR.")
        }

        var stateChanges: [StateChange] = []

        // Change 1: Add .worn (if not already worn)
        if itemSnapshot.attributes[.isWorn] != .bool(true) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemDynamicValue(key: .isWorn),
                oldValue: itemSnapshot.attributes[.isWorn] ?? .bool(false),
                newValue: .bool(true)
            ))
        }

        // Change 2: Add .touched (if not already touched)
        if itemSnapshot.attributes[.itemTouched] != .bool(true) {
            stateChanges.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemDynamicValue(key: .itemTouched),
                oldValue: itemSnapshot.attributes[.itemTouched] ?? .bool(false),
                newValue: .bool(true)
            ))
        }

        // Update pronoun "it"
        stateChanges.append(StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([targetItemID])
        ))

        // --- Prepare Result ---
        let message = "You put on the \(itemSnapshot.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
