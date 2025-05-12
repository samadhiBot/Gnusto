import Foundation

/// Handles the "TOUCH" context.command and its synonyms (e.g., "FEEL", "RUB", "PAT").
public struct TouchActionHandler: ActionHandler {
    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.custom("Touch what?")
        }

        // 2. Check if item exists
        guard await context.engine.item(targetItemID) != nil else {
            throw ActionResponse.unknownItem(targetItemID)        }

        // 3. Check reachability
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            throw ActionResponse.internalEngineError(
                "TOUCH context.command reached process without direct object."
            )
        }

        // --- State Change: Mark as Touched ---
        var stateChanges: [StateChange] = []
        // Get snapshot again to ensure properties are current
        if let targetItem = await context.engine.item(targetItemID) {
            if targetItem.attributes[.isTouched] != true {
                stateChanges.append(StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: targetItem.attributes[.isTouched] ?? false,
                    newValue: true,
                ))
            }
        } else {
            // Should not happen if validate passed
            throw ActionResponse.internalEngineError(
                "Target item '\(targetItemID)' disappeared between validate and process for TOUCH."
            )
        }

        // TODO: Allow item-specific touch actions via ItemActionHandler?

        // --- Create Result ---
        return ActionResult(
            success: true,
            message: "You feel nothing special.",
            stateChanges: stateChanges
        )
    }
}
